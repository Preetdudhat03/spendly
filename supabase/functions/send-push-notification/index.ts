import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
const FCM_SERVER_KEY = Deno.env.get("FCM_SERVER_KEY") ?? "";

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

interface WebhookPayload {
  type: "INSERT" | "UPDATE" | "DELETE";
  table: string;
  schema: string;
  record: {
    id: string;
    user_id?: string | null;
    family_id: string;
    type: string;
    title: string;
    body: string;
    payload?: Record<string, unknown>;
    priority?: string;
    deep_link?: string;
    created_by?: string | null;
    created_at: string;
  };
}

serve(async (req) => {
  try {
    if (req.method !== "POST") {
      return new Response(JSON.stringify({ error: "Method not allowed" }), {
        status: 405,
        headers: { "Content-Type": "application/json" },
      });
    }

    const body: WebhookPayload = await req.json();
    const record = body.record;

    if (!record || !record.family_id) {
      return new Response(JSON.stringify({ message: "No valid record found" }), {
        status: 200,
        headers: { "Content-Type": "application/json" },
      });
    }

    console.log(`[PushFunction] Processing notification ${record.id} for family ${record.family_id}`);

    // 1. Get all members of the family (excluding creator)
    let membersQuery = supabase
      .from("family_members")
      .select("user_id")
      .eq("family_id", record.family_id);

    if (record.created_by) {
      membersQuery = membersQuery.neq("user_id", record.created_by);
    }

    // If targeted to a single specific user
    if (record.user_id) {
      membersQuery = membersQuery.eq("user_id", record.user_id);
    }

    const { data: familyMembers, error: membersError } = await membersQuery;

    if (membersError || !familyMembers || familyMembers.length === 0) {
      console.log("[PushFunction] No eligible family members found to notify");
      return new Response(JSON.stringify({ message: "No recipients" }), {
        status: 200,
        headers: { "Content-Type": "application/json" },
      });
    }

    const targetUserIds = familyMembers.map((m) => m.user_id);

    // 2. Filter by user preferences
    const { data: preferences } = await supabase
      .from("notification_preferences")
      .select("*")
      .in("user_id", targetUserIds);

    const allowedUserIds = targetUserIds.filter((userId) => {
      const pref = preferences?.find((p) => p.user_id === userId);
      if (!pref) return true; // Default enabled
      if (!pref.push_enabled) return false;

      const type = record.type;
      if (type.startsWith("expense_")) return pref.expense_alerts ?? true;
      if (type.startsWith("budget_")) return pref.budget_alerts ?? true;
      if (type.startsWith("family_")) return pref.family_alerts ?? true;
      if (type.startsWith("spending_")) return pref.spending_insights ?? true;
      return true;
    });

    if (allowedUserIds.length === 0) {
      console.log("[PushFunction] All recipients have muted notifications");
      return new Response(JSON.stringify({ message: "Muted by preferences" }), {
        status: 200,
        headers: { "Content-Type": "application/json" },
      });
    }

    // 3. Fetch active device tokens
    const { data: deviceTokens, error: tokenError } = await supabase
      .from("user_device_tokens")
      .select("id, push_token, device_token, user_id, platform")
      .in("user_id", allowedUserIds)
      .eq("is_active", true);

    if (tokenError || !deviceTokens || deviceTokens.length === 0) {
      console.log("[PushFunction] No registered device tokens found for recipients");
      return new Response(JSON.stringify({ message: "No device tokens registered" }), {
        status: 200,
        headers: { "Content-Type": "application/json" },
      });
    }

    console.log(`[PushFunction] Dispatching push to ${deviceTokens.length} devices`);

    // 4. Send FCM Push Notification
    const pushPromises = deviceTokens.map(async (device: any) => {
      if (!FCM_SERVER_KEY) {
        console.warn("[PushFunction] FCM_SERVER_KEY not configured in Supabase environment secrets");
        return { success: false, reason: "No FCM_SERVER_KEY" };
      }

      const recipientToken = device.push_token || device.device_token;
      if (!recipientToken) {
        console.warn(`[PushFunction] Device ${device.id} has no valid token`);
        return { success: false, reason: "Empty token" };
      }

      const fcmPayload = {
        to: recipientToken,
        notification: {
          title: record.title,
          body: record.body,
          sound: "default",
          android_channel_id: "spendly_alerts",
        },
        data: {
          notification_id: record.id,
          family_id: record.family_id,
          type: record.type,
          deep_link: record.deep_link || "/expenses",
          created_at: record.created_at,
          ...(record.payload || {}),
        },
        priority: "high",
      };

      try {
        const response = await fetch("https://fcm.googleapis.com/fcm/send", {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            Authorization: `key=${FCM_SERVER_KEY}`,
          },
          body: JSON.stringify(fcmPayload),
        });

        const textResponse = await response.text();
        let result: any;
        try {
          result = JSON.parse(textResponse);
        } catch {
          result = { raw: textResponse };
        }

        console.log(`[PushFunction] FCM response status: ${response.status} | body: ${JSON.stringify(result)}`);

        // Handle unregistered / stale tokens
        if (result.results?.[0]?.error === "NotRegistered" || result.results?.[0]?.error === "InvalidRegistration") {
          await supabase
            .from("user_device_tokens")
            .update({ is_active: false })
            .eq("id", device.id);
          console.log(`[PushFunction] Deactivated stale device token ${device.id}`);
        }

        return { status: response.status, result };
      } catch (err) {
        console.error(`[PushFunction] Error sending to token ${device.push_token}:`, err);
        return { error: String(err) };
      }
    });

    const results = await Promise.all(pushPromises);

    return new Response(JSON.stringify({ success: true, count: results.length }), {
      status: 200,
      headers: { "Content-Type": "application/json" },
    });
  } catch (error) {
    console.error("[PushFunction] Fatal error:", error);
    return new Response(JSON.stringify({ error: String(error) }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }
});
