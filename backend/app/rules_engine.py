"""Детерминированный движок права на упрощённый Европротокол (Узбекистан).

ВАЖНО (принцип из ТЗ): источник истины по праву — это детерминированная логика,
которую ведут юристы/комплаенс. LLM может ОБЪЯСНИТЬ правила по-узбекски/по-русски,
но НЕ является источником решения. Поэтому здесь — обычный код, без ИИ.
"""
from __future__ import annotations

RULES_VERSION = "2026-09-uz-1"  # версионируем: правила меняются независимо от релизов приложения

# Вопросы визарда — единый источник для мобильного клиента (рендерит по этому списку).
WIZARD_QUESTIONS: list[dict] = [
    {"key": "anyone_injured", "type": "bool",
     "label": "Есть пострадавшие (травмы у людей)?"},
    {"key": "pedestrian_involved", "type": "bool",
     "label": "Задет пешеход?"},
    {"key": "vehicle_count", "type": "int",
     "label": "Сколько ТС участвовало в ДТП?", "default": 2},
    {"key": "third_party_property_damaged", "type": "bool",
     "label": "Повреждено чужое имущество / дорожное оборудование?"},
    {"key": "both_insured", "type": "bool",
     "label": "У обоих водителей есть действующая страховка (ОСГО)?"},
    {"key": "documents_valid", "type": "bool",
     "label": "У обоих есть права и документы на ТС?"},
    {"key": "intoxication_suspected", "type": "bool",
     "label": "Есть подозрение на опьянение у кого-то из водителей?"},
    {"key": "damage_disagreement", "type": "bool",
     "label": "Есть разногласия по характеру/перечню повреждений?"},
    {"key": "fault_accepted", "type": "bool",
     "label": "Один водитель полностью признаёт свою вину?"},
]

# Правила: каждое — (условие-«стоп», код, сообщение, действие)
# Условие получает нормализованные ответы и возвращает True, если упрощённый флоу НЕВОЗМОЖЕН.
_RED_RULES: list[tuple] = [
    (lambda a: a["anyone_injured"], "injured",
     "Есть пострадавшие — упрощённый порядок невозможен.",
     "Вызовите экстренные службы и оформляйте с сотрудниками."),
    (lambda a: a["pedestrian_involved"], "pedestrian",
     "Задет пешеход — вне упрощённого порядка.",
     "Оформление с участием сотрудников органов."),
    (lambda a: a["vehicle_count"] != 2, "vehicle_count",
     "В упрощённом порядке участвуют ровно два ТС.",
     "Оформление с участием сотрудников органов."),
    (lambda a: a["third_party_property_damaged"], "third_party_property",
     "Повреждено чужое имущество/дорожное оборудование.",
     "Оформление с участием сотрудников органов."),
    (lambda a: not a["both_insured"], "no_insurance",
     "Не у всех действующая страховка — условие не выполнено.",
     "Уточните полис или оформляйте официально."),
    (lambda a: not a["documents_valid"], "no_documents",
     "Нет необходимых документов (права/на ТС).",
     "Покажите точное недостающее требование."),
    (lambda a: a["intoxication_suspected"], "intoxication",
     "Подозрение на опьянение — упрощённый порядок невозможен.",
     "Оформление с участием сотрудников органов."),
    (lambda a: a["damage_disagreement"], "damage_disagreement",
     "Есть разногласия по повреждениям — флоу небезопасен.",
     "Сохраните доказательства и остановите упрощённый порядок."),
    (lambda a: not a["fault_accepted"], "fault_not_accepted",
     "Ни один водитель не признаёт вину полностью.",
     "Оформление с участием сотрудников органов."),
]

_DEFAULTS = {q["key"]: (q.get("default") if q["type"] == "int" else False) for q in WIZARD_QUESTIONS}


def evaluate_eligibility(answers: dict) -> dict:
    """Вернуть вердикт: green (можно) / red (нельзя) + причины и версия правил."""
    a = {**_DEFAULTS, **(answers or {})}

    reasons = [
        {"code": code, "message": msg, "action": action}
        for cond, code, msg, action in _RED_RULES
        if cond(a)
    ]

    result = "red" if reasons else "green"
    return {
        "result": result,
        "reasons": reasons,
        "rules_version": RULES_VERSION,
        "normalized_answers": a,
    }
