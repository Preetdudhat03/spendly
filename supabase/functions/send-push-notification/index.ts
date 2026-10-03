import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
const FIREBASE_SERVICE_ACCOUNT_RAW = Deno.env.get("FIREBASE_SERVICE_ACCOUNT") ?? Deno.env.get("FCM_SERVER_KEY") ?? "";

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

interface ServiceAccount {
  project_id: string;
  client_email: string;
  private_key: string;
}

// Generate Google OAuth2 Access Token for FCM HTTP v1 API
async function getGoogleAccessToken(serviceAccount: ServiceAccount): Promise<string> {
  const iat = Math.floor(Date.now() / 1000);
  const exp = iat + 3600;

  const header = {
    alg: "RS256",
    typ: "JWT",
  };

  const claimSet = {
    iss: serviceAccount.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    exp: exp,
    iat: iat,
  };

  const encodeBase64Url = (obj: Record<string, unknown>) => {
    return btoa(JSON.stringify(obj))
      .replace(/=/g, "")
      .replace(/\+/g, "-")
      .replace(/\//g, "_");
  };

  const encodedHeader = encodeBase64Url(header);
  const encodedClaimSet = encodeBase64Url(claimSet);
  const unsignedJwt = `${encodedHeader}.${encodedClaimSet}`;

  // Clean PEM delimiters and whitespace
  const pem = serviceAccount.private_key
    .replace(/-----[^-]+-----/g, "")
    .replace(/\s+/g, "")
    .trim();

  const binaryDer = Uint8Array.from(atob(pem), (c) => c.charCodeAt(0));

  const cryptoKey = await crypto.subtle.importKey(
    "pkcs8",
    binaryDer.buffer,
    {
      name: "RSASSA-PKCS1-v1_5",
      hash: "SHA-256",
    },
    false,
    ["sign"]
  );

  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    cryptoKey,
    new TextEncoder().encode(unsignedJwt)
  );

  const encodedSignature = btoa(String.fromCharCode(...new Uint8Array(signature)))
    .replace(/=/g, "")
    .replace(/\+/g, "-")
    .replace(/\//g, "_");

  const signedJwt = `${unsignedJwt}.${encodedSignature}`;

  const response = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: signedJwt,
    }),
  });

  const data = await response.json();
  if (!data.access_token) {
    throw new Error(`Failed to obtain Google access token: ${JSON.stringify(data)}`);
  }
  return data.access_token;
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

    // Deduplicate device tokens to ensure each physical token receives only one push
    const uniqueTokensMap = new Map<string, any>();
    for (const device of deviceTokens) {
      const token = device.push_token || device.device_token;
      if (token && !uniqueTokensMap.has(token)) {
        uniqueTokensMap.set(token, device);
      }
    }
    const uniqueDevices = Array.from(uniqueTokensMap.values());

    console.log(`[PushFunction] Dispatching push to ${uniqueDevices.length} unique devices`);

    // Parse Service Account if provided
    let serviceAccount: ServiceAccount | null = null;
    let googleAccessToken: string | null = null;

    if (FIREBASE_SERVICE_ACCOUNT_RAW.trim().startsWith("{")) {
      try {
        serviceAccount = JSON.parse(FIREBASE_SERVICE_ACCOUNT_RAW);
        if (serviceAccount?.client_email && serviceAccount?.private_key) {
          googleAccessToken = await getGoogleAccessToken(serviceAccount);
          console.log("[PushFunction] Obtained Google OAuth2 token for FCM v1 API");
        }
      } catch (saError) {
        console.error("[PushFunction] Failed to parse service account or get token:", saError);
      }
    }

    // 4. Send FCM Push Notification (HTTP v1 or Legacy)
    const pushPromises = uniqueDevices.map(async (device: any) => {
      const recipientToken = device.push_token || device.device_token;
      if (!recipientToken) {
        return { success: false, reason: "Empty token" };
      }

      // Approach A: Modern FCM HTTP v1 API
      if (googleAccessToken && serviceAccount) {
        const projectId = serviceAccount.project_id || "spendly-9e3fe";
        const fcmV1Url = `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`;

        // Flatten payload data to strings (FCM requirement)
        const customData: Record<string, string> = {
          notification_id: String(record.id),
          family_id: String(record.family_id),
          type: String(record.type),
          deep_link: String(record.deep_link || "/expenses"),
          created_at: String(record.created_at),
        };

        if (record.payload) {
          for (const [k, v] of Object.entries(record.payload)) {
            customData[k] = typeof v === "object" ? JSON.stringify(v) : String(v);
          }
        }

        const v1Payload = {
          message: {
            token: recipientToken,
            notification: {
              title: record.title,
              body: record.body,
            },
            data: customData,
            android: {
              priority: "high",
              collapse_key: String(record.id),
              notification: {
                channel_id: "spendly_alerts",
                sound: "default",
                default_vibrate_timings: true,
                notification_priority: "priority_high",
                tag: String(record.id),
              },
            },
          },
        };

        try {
          const response = await fetch(fcmV1Url, {
            method: "POST",
            headers: {
              "Content-Type": "application/json",
              Authorization: `Bearer ${googleAccessToken}`,
            },
            body: JSON.stringify(v1Payload),
          });

          const result = await response.json();
          console.log(`[PushFunction] FCM v1 response status: ${response.status} | body: ${JSON.stringify(result)}`);

          if (response.status === 404 || result.error?.code === 404 || result.error?.message?.includes("UNREGISTERED")) {
            await supabase.from("user_device_tokens").update({ is_active: false }).eq("id", device.id);
            console.log(`[PushFunction] Deactivated stale token ${device.id}`);
          }

          return { status: response.status, result };
        } catch (v1Err) {
          console.error(`[PushFunction] FCM v1 Error sending to ${recipientToken}:`, v1Err);
          return { error: String(v1Err) };
        }
      }

      // Approach B: Fallback to Legacy HTTP endpoint
      const legacyKey = FIREBASE_SERVICE_ACCOUNT_RAW;
      if (!legacyKey) {
        console.warn("[PushFunction] No FCM credentials configured in Supabase environment secrets");
        return { success: false, reason: "No credentials" };
      }

      const legacyPayload = {
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
            Authorization: `key=${legacyKey}`,
          },
          body: JSON.stringify(legacyPayload),
        });

        const textResponse = await response.text();
        let result: any;
        try {
          result = JSON.parse(textResponse);
        } catch {
          result = { raw: textResponse };
        }

        console.log(`[PushFunction] FCM legacy response status: ${response.status} | body: ${JSON.stringify(result)}`);

        if (result.results?.[0]?.error === "NotRegistered" || result.results?.[0]?.error === "InvalidRegistration") {
          await supabase.from("user_device_tokens").update({ is_active: false }).eq("id", device.id);
          console.log(`[PushFunction] Deactivated stale device token ${device.id}`);
        }

        return { status: response.status, result };
      } catch (err) {
        console.error(`[PushFunction] Error sending to legacy token ${recipientToken}:`, err);
        return { error: String(err) };
      }
    });

    const results = await Promise.all(pushPromises);

    return new Response(JSON.stringify({ success: true, count: results.length, results }), {
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
