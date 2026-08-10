#!/usr/bin/env python3
"""Generate MPSeCNet module track sheet: Login → Dashboard → Modules (English)."""

from __future__ import annotations

from pathlib import Path

from openpyxl import Workbook
from openpyxl.styles import Alignment, Border, Font, PatternFill, Side
from openpyxl.utils import get_column_letter
from openpyxl.worksheet.datavalidation import DataValidation

ROOT = Path(__file__).resolve().parent
OUT_XLSX = ROOT / "MPSeCNet_Module_Wise_Work_Track_Sheet.xlsx"
OUT_HTML = ROOT / "MPSeCNet_Module_Wise_Work_Track_Sheet.html"
OUT_PDF = ROOT / "MPSeCNet_Module_Wise_Work_Track_Sheet.pdf"

STATUS = {
    "Ready": "Module complete — available for use / internal check",
    "UAT": "Development complete — department testing / confirmation pending",
    "In Progress": "Development is ongoing",
    "Not Started": "Not started for current release",
    "Pending Dept": "Awaiting department decision / input",
}

# #, Flow, Module, Status, %, Started, Target Complete, Latest, Done, Remaining
MODULES = [
    (
        1,
        "1. Login",
        "App Login / Officer Login",
        "Ready",
        100,
        "18-Jun-2026",
        "Completed",
        "27-Jul-2026",
        "Guest and officer / service login working",
        "—",
    ),
    (
        2,
        "1. Login",
        "Presiding Officer Login",
        "Ready",
        100,
        "Jul-2026",
        "Completed",
        "05-Aug-2026",
        "Separate PO login with session and elector counts",
        "—",
    ),
    (
        3,
        "2. Dashboard",
        "Home Dashboard (service tiles)",
        "Ready",
        100,
        "18-Jun-2026",
        "Completed",
        "07-Aug-2026",
        "Voter Services and About Elections home sections",
        "—",
    ),
    (
        4,
        "3. Dashboard → Voter Services",
        "EMS",
        "UAT",
        100,
        "07-Aug-2026",
        "08–12 Aug 2026",
        "07-Aug-2026",
        "Home tile opens EMS login page in WebView",
        "Department device check and sign-off",
    ),
    (
        5,
        "3. Dashboard → Voter Services",
        "Find Voter",
        "Ready",
        95,
        "Jul-2026",
        "Completed",
        "06-Aug-2026",
        "Search, filters, Hindi input support, voter slip",
        "Optional field photo edge-case check",
    ),
    (
        6,
        "3. Dashboard → Voter Services",
        "Claim / Objection Application",
        "UAT",
        100,
        "Jul-2026",
        "08–15 Aug 2026",
        "27-Jul-2026",
        "Home tile opens claim / objection portal",
        "End-to-end check on external portal by department",
    ),
    (
        7,
        "4. Dashboard → About Elections",
        "Online Nomination (Urban)",
        "UAT",
        85,
        "07-Jul-2026",
        "10–20 Aug 2026",
        "07-Aug-2026",
        "OLINAPI masters, form steps, local draft save",
        "Department UAT and registration acceptance",
    ),
    (
        8,
        "4. Dashboard → About Elections",
        "Online Nomination (Panchayat)",
        "In Progress",
        45,
        "21-Jul-2026",
        "25 Aug – 05 Sep 2026",
        "07-Aug-2026",
        "Entry UI / path started",
        "Panchayat masters and full submit flow",
    ),
    (
        9,
        "4. Dashboard → About Elections",
        "Polling Station Survey",
        "UAT",
        90,
        "23-Jun-2026",
        "10–18 Aug 2026",
        "20-Jul-2026",
        "Urban / rural dropdowns; survey open and save",
        "Live survey save UAT by department",
    ),
    (
        10,
        "4. Dashboard → About Elections",
        "Presiding Officer",
        "Ready",
        95,
        "30-Jun-2026",
        "Completed",
        "05-Aug-2026",
        "Milestones, booth map, turnout, sync",
        "Optional election-day field UAT",
    ),
    (
        11,
        "4. Dashboard → About Elections",
        "Election Expenditure Accounts",
        "Not Started",
        0,
        "—",
        "As per department priority",
        "—",
        "Portal URL identified; home release pending priority",
        "Department go-ahead, home release, then UAT",
    ),
    (
        12,
        "5. Next phase (after current UAT)",
        "EVM Scanning (CU / BU)",
        "In Progress",
        70,
        "18-Jun-2026",
        "As per department priority",
        "31-Jul-2026",
        "Day-1 module: CU / BU and scanner screens prepared",
        "Priority confirmation → finish and release in app",
    ),
    (
        13,
        "5. Next phase (after current UAT)",
        "Reports",
        "Not Started",
        40,
        "Jun-2026",
        "As per department priority",
        "—",
        "Basic reports UI scaffolding",
        "Confirm API need with department → complete",
    ),
    (
        14,
        "6. Support (app-wide)",
        "Profile / Settings / English–Hindi",
        "Ready",
        95,
        "23-Jun-2026",
        "Completed",
        "07-Aug-2026",
        "Branding, language, profile fields",
        "Minor copy updates as requested",
    ),
    (
        15,
        "6. Support (app-wide)",
        "Offline / Sync",
        "Ready",
        90,
        "23-Jun-2026",
        "Completed",
        "02-Jul-2026",
        "Offline hub and sync queue",
        "Optional field stress test",
    ),
    (
        16,
        "6. Support (app-wide)",
        "Reminders / Notifications",
        "Pending Dept",
        75,
        "28-Jul-2026",
        "After department timings confirmed",
        "29-Jul-2026",
        "iOS / Android notification technical fix done",
        "Official schedule and message text from department",
    ),
]

TIMELINE = [
    ("Week 1", "18–22 Jun 2026", "Login and Dashboard foundation; EVM scanning started (Day 1)"),
    ("Week 2", "23–29 Jun 2026", "English / Hindi; Survey WebView; Offline; Profile"),
    ("Week 3", "30 Jun–6 Jul 2026", "Presiding Officer screens started"),
    ("Week 4", "7–13 Jul 2026", "API connection; Dashboard modules expanded; Nomination started"),
    ("Week 5", "14–20 Jul 2026", "Polling Station Survey urban / rural fixes"),
    ("Week 6", "21–27 Jul 2026", "Nomination Urban; PO live turnout; branding; APK"),
    ("Week 7", "28–31 Jul 2026", "Notifications fix"),
    ("Week 8", "1–5 Aug 2026", "Presiding Officer completed"),
    ("Week 9", "6 Aug 2026", "Find Voter completed"),
    ("Week 10", "7 Aug 2026", "EMS on Dashboard; Nomination on Dashboard for UAT"),
]

THIN = Border(
    left=Side(style="thin", color="BFC9D6"),
    right=Side(style="thin", color="BFC9D6"),
    top=Side(style="thin", color="BFC9D6"),
    bottom=Side(style="thin", color="BFC9D6"),
)

FILLS = {
    "Ready": PatternFill("solid", fgColor="C6F6D5"),
    "UAT": PatternFill("solid", fgColor="BEE3F8"),
    "In Progress": PatternFill("solid", fgColor="FEFCBF"),
    "Not Started": PatternFill("solid", fgColor="FED7D7"),
    "Pending Dept": PatternFill("solid", fgColor="FBB6CE"),
}

HEADER_FILL = PatternFill("solid", fgColor="0B2A4A")
HEADER_FONT = Font(bold=True, color="FFFFFF", name="Calibri", size=11)
TITLE_FONT = Font(bold=True, color="0B2A4A", name="Calibri", size=16)
SUB_FONT = Font(bold=True, color="1D4ED8", name="Calibri", size=12)
BODY_FONT = Font(name="Calibri", size=10)

COUNTS: dict[str, int] = {k: 0 for k in STATUS}
for m in MODULES:
    COUNTS[m[3]] = COUNTS.get(m[3], 0) + 1


def style_header(ws, row: int, cols: int) -> None:
    for c in range(1, cols + 1):
        cell = ws.cell(row=row, column=c)
        cell.fill = HEADER_FILL
        cell.font = HEADER_FONT
        cell.alignment = Alignment(wrap_text=True, vertical="center", horizontal="center")
        cell.border = THIN


def autosize(ws, widths: dict[int, float]) -> None:
    for col, w in widths.items():
        ws.column_dimensions[get_column_letter(col)].width = w


def build_workbook() -> Workbook:
    wb = Workbook()

    ws = wb.active
    ws.title = "01_Summary"
    ws["A1"] = "MPSeCNet — Module Work Track Sheet"
    ws["A1"].font = TITLE_FONT
    ws["A2"] = "Easy tracking: Login → Dashboard → Modules  |  When will it be complete?"
    ws["A2"].font = SUB_FONT
    ws.merge_cells("A1:E1")
    ws.merge_cells("A2:E2")

    meta = [
        ("Project", "MPSeCNet"),
        ("Flow", "Login → Dashboard → Modules"),
        ("Day 1 start", "18 June 2026"),
        ("As-of date", "07 August 2026"),
        ("Prepared by", "Mayur Bobade, Associate Engineer"),
        (
            "How to use",
            "Use Status and Target Complete columns to track when each module will be ready",
        ),
    ]
    r = 4
    for k, v in meta:
        ws.cell(row=r, column=1, value=k).font = Font(bold=True, name="Calibri", size=10)
        ws.cell(row=r, column=2, value=v).font = BODY_FONT
        ws.merge_cells(start_row=r, start_column=2, end_row=r, end_column=4)
        r += 1

    r += 1
    ws.cell(row=r, column=1, value="Status count").font = SUB_FONT
    r += 1
    for i, h in enumerate(["Status", "Modules", "Meaning"], 1):
        ws.cell(row=r, column=i, value=h)
    style_header(ws, r, 3)
    r += 1
    for status, meaning in STATUS.items():
        ws.cell(row=r, column=1, value=status).fill = FILLS[status]
        ws.cell(row=r, column=1).border = THIN
        ws.cell(row=r, column=1).font = Font(bold=True, name="Calibri", size=10)
        ws.cell(row=r, column=2, value=COUNTS.get(status, 0)).border = THIN
        ws.cell(row=r, column=2).alignment = Alignment(horizontal="center")
        ws.cell(row=r, column=3, value=meaning).border = THIN
        ws.cell(row=r, column=3).font = BODY_FONT
        r += 1

    r += 1
    ws.cell(row=r, column=1, value="Application flow").font = SUB_FONT
    r += 1
    for line in [
        "Step 1 → Login (App / Officer / Presiding Officer)",
        "Step 2 → Dashboard (Home)",
        "Step 3 → Voter Services: EMS | Find Voter | Claim / Objection",
        "Step 4 → About Elections: Nomination | Survey | Presiding Officer | Expenditure",
        "Step 5 → Next phase: EVM Scanning | Reports",
        "Step 6 → Support: Profile, Offline, Notifications",
    ]:
        ws.cell(row=r, column=1, value=line).font = BODY_FONT
        ws.merge_cells(start_row=r, start_column=1, end_row=r, end_column=4)
        r += 1

    autosize(ws, {1: 36, 2: 14, 3: 70, 4: 20, 5: 20})

    ws2 = wb.create_sheet("02_Module_Track")
    headers = [
        "#",
        "App flow",
        "Module",
        "Status",
        "% Done",
        "Started",
        "Target complete",
        "Latest update",
        "What is done",
        "Remaining (to complete)",
    ]
    for i, h in enumerate(headers, 1):
        ws2.cell(row=1, column=i, value=h)
    style_header(ws2, 1, len(headers))
    ws2.row_dimensions[1].height = 36
    ws2.freeze_panes = "A2"
    ws2.auto_filter.ref = f"A1:J{len(MODULES) + 1}"

    for i, m in enumerate(MODULES, 2):
        for c, val in enumerate(m, 1):
            cell = ws2.cell(row=i, column=c, value=val)
            cell.font = BODY_FONT
            cell.border = THIN
            cell.alignment = Alignment(wrap_text=True, vertical="top")
        ws2.cell(row=i, column=4).fill = FILLS.get(m[3], PatternFill())
        ws2.cell(row=i, column=4).alignment = Alignment(
            horizontal="center", vertical="center"
        )
        ws2.cell(row=i, column=5).alignment = Alignment(
            horizontal="center", vertical="center"
        )
        tgt = ws2.cell(row=i, column=7)
        if str(m[6]).lower() == "completed":
            tgt.fill = PatternFill("solid", fgColor="C6F6D5")
        elif "aug" in str(m[6]).lower() or "sep" in str(m[6]).lower():
            tgt.fill = PatternFill("solid", fgColor="FEFCBF")
        ws2.row_dimensions[i].height = 44

    dv = DataValidation(
        type="list",
        formula1='"Ready,UAT,In Progress,Not Started,Pending Dept"',
        allow_blank=False,
    )
    ws2.add_data_validation(dv)
    dv.add(f"D2:D{len(MODULES) + 1}")

    autosize(
        ws2,
        {
            1: 4,
            2: 34,
            3: 36,
            4: 14,
            5: 10,
            6: 14,
            7: 24,
            8: 14,
            9: 42,
            10: 40,
        },
    )

    ws3 = wb.create_sheet("03_Dashboard_Modules")
    ws3["A1"] = "Dashboard modules — when will it be complete? (quick view)"
    ws3["A1"].font = SUB_FONT
    ws3.merge_cells("A1:F1")
    for i, h in enumerate(
        ["#", "Dashboard module", "Status", "%", "Target complete", "Remaining"], 1
    ):
        ws3.cell(row=3, column=i, value=h)
    style_header(ws3, 3, 6)

    quick = [m for m in MODULES if m[0] in (3, 4, 5, 6, 7, 8, 9, 10, 11)]
    for i, m in enumerate(quick, 4):
        vals = (m[0], m[2], m[3], f"{m[4]}%", m[6], m[9])
        for c, val in enumerate(vals, 1):
            cell = ws3.cell(row=i, column=c, value=val)
            cell.font = BODY_FONT
            cell.border = THIN
            cell.alignment = Alignment(wrap_text=True, vertical="top")
        ws3.cell(row=i, column=3).fill = FILLS.get(m[3], PatternFill())
        ws3.row_dimensions[i].height = 36
    autosize(ws3, {1: 4, 2: 42, 3: 14, 4: 8, 5: 24, 6: 44})

    ws4 = wb.create_sheet("04_Week_Timeline")
    for i, h in enumerate(["Week", "Period", "Work carried out"], 1):
        ws4.cell(row=1, column=i, value=h)
    style_header(ws4, 1, 3)
    for i, t in enumerate(TIMELINE, 2):
        for c, val in enumerate(t, 1):
            cell = ws4.cell(row=i, column=c, value=val)
            cell.font = BODY_FONT
            cell.border = THIN
            cell.alignment = Alignment(wrap_text=True, vertical="top")
        ws4.row_dimensions[i].height = 28
    autosize(ws4, {1: 10, 2: 18, 3: 82})

    ws5 = wb.create_sheet("05_Status_Meaning")
    ws5["A1"] = "Status meaning"
    ws5["A1"].font = SUB_FONT
    for i, h in enumerate(["Status", "Meaning"], 1):
        ws5.cell(row=3, column=i, value=h)
    style_header(ws5, 3, 2)
    for i, (k, v) in enumerate(STATUS.items(), 4):
        ws5.cell(row=i, column=1, value=k).fill = FILLS[k]
        ws5.cell(row=i, column=1).border = THIN
        ws5.cell(row=i, column=1).font = Font(bold=True, name="Calibri", size=10)
        ws5.cell(row=i, column=2, value=v).border = THIN
        ws5.cell(row=i, column=2).font = BODY_FONT
    autosize(ws5, {1: 14, 2: 78})

    return wb


def badge(status: str) -> str:
    colors = {
        "Ready": ("#166534", "#dcfce7"),
        "UAT": ("#1e40af", "#dbeafe"),
        "In Progress": ("#854d0e", "#fef9c3"),
        "Not Started": ("#991b1b", "#fee2e2"),
        "Pending Dept": ("#9d174d", "#fce7f3"),
    }
    fg, bg = colors.get(status, ("#0f172a", "#f1f5f9"))
    return (
        f'<span style="display:inline-block;padding:2px 8px;border-radius:4px;'
        f'font-weight:700;font-size:8.5pt;color:{fg};background:{bg};">{status}</span>'
    )


def build_html() -> str:
    summary_rows = "".join(
        f"<tr><td>{badge(k)}</td><td style='text-align:center'>{COUNTS.get(k, 0)}</td><td>{v}</td></tr>"
        for k, v in STATUS.items()
    )
    module_rows = "".join(
        f"<tr><td>{m[0]}</td><td>{m[1]}</td><td><strong>{m[2]}</strong></td>"
        f"<td>{badge(m[3])}</td><td style='text-align:center'>{m[4]}%</td>"
        f"<td>{m[5]}</td><td><strong>{m[6]}</strong></td><td>{m[7]}</td>"
        f"<td>{m[8]}</td><td>{m[9]}</td></tr>"
        for m in MODULES
    )
    quick = [m for m in MODULES if m[0] in (3, 4, 5, 6, 7, 8, 9, 10, 11)]
    quick_rows = "".join(
        f"<tr><td><strong>{m[2]}</strong></td><td>{badge(m[3])}</td>"
        f"<td style='text-align:center'>{m[4]}%</td><td><strong>{m[6]}</strong></td>"
        f"<td>{m[9]}</td></tr>"
        for m in quick
    )
    timeline_rows = "".join(
        f"<tr><td>{a}</td><td>{b}</td><td>{c}</td></tr>" for a, b, c in TIMELINE
    )

    return f"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8"/>
<title>MPSeCNet — Module Work Track Sheet</title>
<style>
  @page {{ size: A4 landscape; margin: 10mm; }}
  body {{ font-family: "Helvetica Neue", Helvetica, Arial, sans-serif; font-size: 9pt; color: #15202b; line-height: 1.35; }}
  h1 {{ font-size: 16pt; color: #0b2a4a; margin: 0 0 2pt 0; }}
  h2 {{ font-size: 11.5pt; color: #0b2a4a; margin: 12pt 0 6pt 0; padding-bottom: 3pt; border-bottom: 1.5px solid #1d4ed8; }}
  p {{ margin: 3pt 0 6pt 0; }}
  table {{ width: 100%; border-collapse: collapse; margin: 6pt 0 10pt 0; font-size: 7.8pt; }}
  th, td {{ border: 1px solid #bfc9d6; padding: 3.5pt 4pt; vertical-align: top; text-align: left; }}
  th {{ background: #0b2a4a; color: #fff; }}
  tr:nth-child(even) td {{ background: #f8fafc; }}
  tr {{ page-break-inside: avoid; }}
  table.meta td {{ border: none; padding: 2pt 8pt 2pt 0; background: transparent !important; }}
  table.meta td:first-child {{ font-weight: 700; color: #475569; width: 140px; }}
  .flow {{ background: #eff6ff; border-left: 3px solid #1d4ed8; padding: 6pt 8pt; margin: 6pt 0; }}
  .end {{ color: #64748b; font-size: 8pt; margin-top: 10pt; }}
</style>
</head>
<body>
<h1>MPSeCNet — Module Work Track Sheet</h1>
<p style="color:#1d4ed8;font-weight:600;margin:0 0 8pt 0">Easy tracking: Login → Dashboard → Modules &nbsp;|&nbsp; When will it be complete?</p>
<table class="meta">
<tr><td>Project</td><td>MPSeCNet</td></tr>
<tr><td>Day 1 start</td><td>18 June 2026</td></tr>
<tr><td>As-of date</td><td>07 August 2026</td></tr>
<tr><td>Prepared by</td><td>Mayur Bobade, Associate Engineer</td></tr>
</table>

<div class="flow">
<strong>Application flow:</strong>
Login → Dashboard →
Voter Services (EMS · Find Voter · Claim / Objection) →
About Elections (Nomination · Survey · Presiding Officer · Expenditure) →
Next phase (EVM · Reports)
</div>

<h2>1. Status count</h2>
<table>
<tr><th>Status</th><th>Count</th><th>Meaning</th></tr>
{summary_rows}
</table>

<h2>2. Dashboard modules — when will it be complete? (quick view)</h2>
<table>
<tr><th>Module</th><th>Status</th><th>%</th><th>Target complete</th><th>Remaining</th></tr>
{quick_rows}
</table>

<h2>3. Full track (Login → Dashboard → Modules)</h2>
<table>
<tr>
<th>#</th><th>App flow</th><th>Module</th><th>Status</th><th>%</th>
<th>Started</th><th>Target complete</th><th>Latest</th><th>Done</th><th>Remaining</th>
</tr>
{module_rows}
</table>

<h2>4. Week timeline (from Day 1)</h2>
<table>
<tr><th>Week</th><th>Period</th><th>Work carried out</th></tr>
{timeline_rows}
</table>

<p class="end">End of sheet · Excel companion: MPSeCNet_Module_Wise_Work_Track_Sheet.xlsx · 07 August 2026</p>
</body>
</html>
"""


def main() -> None:
    wb = build_workbook()
    wb.save(OUT_XLSX)
    OUT_HTML.write_text(build_html(), encoding="utf-8")
    print(f"Wrote {OUT_XLSX}")
    print(f"Wrote {OUT_HTML}")


if __name__ == "__main__":
    main()
