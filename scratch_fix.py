import re

def process():
    p = r'p:\pro\spendly\lib\features\analytics\models\analytics_models.dart'
    with open(p, 'r', encoding='utf-8') as f:
        c = f.read()

    # DiagnosticIntelligence
    c = c.replace("'purchasesUnder200': purchasesUnder200,", "")
    c = c.replace("purchasesUnder200: json['purchasesUnder200'] as int,", "")

    # BudgetForecast
    c = c.replace("'currentPace': currentPace,", "")
    c = c.replace("currentPace: json['currentPace'] as double,", "")
    c = c.replace("'velocityStatus': velocityStatus.name,", "")
    c = c.replace("velocityStatus: VelocityStatus.values.byName(json['velocityStatus'] as String),", "")
    c = c.replace("'recommendedDailyLimit': recommendedDailyLimit,", "")
    c = c.replace("recommendedDailyLimit: json['recommendedDailyLimit'] as double,", "")

    # SpendingHealth
    c = c.replace("'score': score,", "")
    c = c.replace("score: json['score'] as int,", "")
    c = c.replace("'adherenceScore': adherenceScore,", "")
    c = c.replace("adherenceScore: json['adherenceScore'] as int,", "")
    c = c.replace("'velocityScore': velocityScore,", "")
    c = c.replace("velocityScore: json['velocityScore'] as int,", "")
    c = c.replace("'stabilityScore': stabilityScore,", "")
    c = c.replace("stabilityScore: json['stabilityScore'] as int,", "")
    c = c.replace("'anomalyScore': anomalyScore,", "")
    c = c.replace("anomalyScore: json['anomalyScore'] as int,", "")
    c = c.replace("'concentrationScore': concentrationScore,", "")
    c = c.replace("concentrationScore: json['concentrationScore'] as int,", "")
    c = c.replace("'confidenceScore': confidenceScore,", "")
    c = c.replace("confidenceScore: json['confidenceScore'] as int,", "")

    # InsightFact
    c = c.replace("'factId': factId,", "")
    c = c.replace("factId: json['factId'] as String,", "")
    c = c.replace("'factData': factData,", "")
    c = c.replace("factData: Map<String, dynamic>.from(json['factData']),", "")

    with open(p, 'w', encoding='utf-8') as f:
        f.write(c)

if __name__ == '__main__':
    process()
