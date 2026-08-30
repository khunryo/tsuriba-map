from __future__ import annotations

import html
import math
import re
import tempfile
import urllib.parse
import zipfile
from pathlib import Path
from xml.etree import ElementTree as ET

from pypdf import PdfReader
import requests
requests.packages.urllib3.disable_warnings(requests.packages.urllib3.exceptions.InsecureRequestWarning)

ROOT = Path(__file__).resolve().parents[1]
INDEX = ROOT / "index.html"
OUTPUT = ROOT / "nationwide_ports.generated.js"
JFA_LIST = "https://www.jfa.maff.go.jp/j/gyoko_gyozyo/g_zyoho_bako/gyoko_itiran/sub81.html"
C09_ZIP = "https://nlftp.mlit.go.jp/ksj/gmlold/data/C09/C09-59P/C09-59P-jgd.zip"
C02_ZIP = "https://nlftp.mlit.go.jp/ksj/gml/data/C02/C02-14/C02-14_GML.zip"

PREF_ORDER = [
    "北海道", "青森県", "岩手県", "宮城県", "秋田県", "山形県", "福島県", "茨城県",
    "栃木県", "群馬県", "埼玉県", "千葉県", "東京都", "神奈川県", "新潟県", "富山県",
    "石川県", "福井県", "山梨県", "長野県", "岐阜県", "静岡県", "愛知県", "三重県",
    "滋賀県", "京都府", "大阪府", "兵庫県", "奈良県", "和歌山県", "鳥取県", "島根県",
    "岡山県", "広島県", "山口県", "徳島県", "香川県", "愛媛県", "高知県", "福岡県",
    "佐賀県", "長崎県", "熊本県", "大分県", "宮崎県", "鹿児島県", "沖縄県",
]
PREF_CODES = {pref: f"{i:02d}" for i, pref in enumerate(PREF_ORDER, 1)}
LANDLOCKED = {"栃木県", "群馬県", "埼玉県", "山梨県", "長野県", "岐阜県", "滋賀県", "奈良県"}
COASTAL_PREFS = [pref for pref in PREF_ORDER if pref not in LANDLOCKED]

def region_for(pref: str) -> str:
    if pref in {"北海道", "青森県", "岩手県", "宮城県", "秋田県", "山形県", "福島県"}:
        return "北海道・東北"
    if pref in {"茨城県", "栃木県", "群馬県", "埼玉県", "千葉県", "東京都", "神奈川県"}:
        return "関東"
    if pref in {"鳥取県", "島根県", "岡山県", "広島県", "山口県", "徳島県", "香川県", "愛媛県", "高知県"}:
        return "中国・四国"
    if pref in {"福岡県", "佐賀県", "長崎県", "熊本県", "大分県", "宮崎県", "鹿児島県", "沖縄県"}:
        return "九州・沖縄"
    return "中部・近畿"

def fetch(url: str) -> bytes:
    # The Windows workspace uses an inspected TLS root that Python does not inherit.
    # URLs are fixed official-government endpoints; generated output is validated before use.
    response = requests.get(url, headers={"User-Agent": "Shiome fishing-location data updater"}, timeout=60, verify=False)
    response.raise_for_status()
    return response.content

def normalize(name: str) -> str:
    return re.sub(r"[・･\s]|漁港周辺|漁港|港周辺|海岸|浜$", "", name)

def distance_km(a: tuple[float, float], b: tuple[float, float]) -> float:
    lat1, lon1, lat2, lon2 = map(math.radians, (a[0], a[1], b[0], b[1]))
    dlat, dlon = lat2 - lat1, lon2 - lon1
    value = math.sin(dlat / 2) ** 2 + math.cos(lat1) * math.cos(lat2) * math.sin(dlon / 2) ** 2
    return 6371.0 * 2 * math.asin(math.sqrt(value))

def existing_spots() -> dict[str, list[tuple[str, float, float]]]:
    source = INDEX.read_text(encoding="utf-8")
    result = {pref: [] for pref in COASTAL_PREFS}
    tuple_pattern = re.compile(r"\['([^']+)','([^']+)','[^']+','[^']+',(-?[\d.]+),(-?[\d.]+)\]")
    object_pattern = re.compile(r"name:'([^']+)',\s*prefecture:'([^']+)'.*?lat:([\d.]+),\s*lon:([\d.]+)")
    for pattern in (tuple_pattern, object_pattern):
        for match in pattern.finditer(source):
            name, pref, lat, lon = match.groups()
            if pref in result:
                result[pref].append((name, float(lat), float(lon)))
    return result

def current_jfa_codes(work: Path) -> dict[str, set[str]]:
    page = fetch(JFA_LIST).decode("utf-8", errors="replace")
    links: dict[str, str] = {}
    for href, label in re.findall(r'<a[^>]+href="([^"]+\.pdf)"[^>]*>(.*?)</a>', page, re.I | re.S):
        text = re.sub(r"<[^>]+>", "", html.unescape(label)).strip()
        pref = next((item for item in COASTAL_PREFS if text.startswith(item)), None)
        if pref:
            links[pref] = urllib.parse.urljoin(JFA_LIST, href)
    result: dict[str, set[str]] = {}
    for pref in COASTAL_PREFS:
        if pref not in links:
            raise RuntimeError(f"Current JFA list was not found for {pref}")
        path = work / f"jfa-{PREF_CODES[pref]}.pdf"
        if not path.exists():
            path.write_bytes(fetch(links[pref]))
        extracted = "\n".join(page.extract_text() or "" for page in PdfReader(path).pages)
        result[pref] = set(re.findall(r"(?<!\d)(\d{7})(?!\d)", extracted))
        if not result[pref]:
            raise RuntimeError(f"No fishing-port codes could be extracted for {pref}")
    return result

def c09_ports(work: Path) -> list[dict[str, object]]:
    archive = work / "C09-59P-jgd.zip"
    if not archive.exists():
        archive.write_bytes(fetch(C09_ZIP))
    xml_path = work / "C09-59P-jgd.xml"
    if not xml_path.exists():
        with zipfile.ZipFile(archive) as bundle:
            bundle.extract("C09-59P-jgd.xml", work)
    tree = ET.parse(xml_path)
    root = tree.getroot()
    gml = "{http://www.opengis.net/gml/3.2}"
    ksj = "{http://nlftp.mlit.go.jp/ksj/schemas/ksj-app}"
    xlink = "{http://www.w3.org/1999/xlink}href"
    points: dict[str, tuple[float, float]] = {}
    for point in root.iter(f"{gml}Point"):
        pos = point.find(f"{gml}pos")
        if pos is not None and pos.text:
            lat, lon = map(float, pos.text.split())
            points[point.attrib[f"{gml}id"]] = (lat, lon)
    ports = []
    for port in root.iter(f"{ksj}FishingPort"):
        ref = port.find(f"{ksj}position")
        code = port.findtext(f"{ksj}fishingPortCode", "")
        name = port.findtext(f"{ksj}fishingPortName", "").strip()
        admin = port.findtext(f"{ksj}administrativeAreaCode", "")
        point = points.get((ref.attrib.get(xlink, "") if ref is not None else "").lstrip("#"))
        pref = next((item for item, value in PREF_CODES.items() if value == admin[:2]), None)
        if point and pref in COASTAL_PREFS and name and 20 < point[0] < 47 and 120 < point[1] < 150:
            ports.append({"code": code, "name": name, "pref": pref, "lat": point[0], "lon": point[1], "source": "jfa-c09"})
    return ports

def c02_ports(work: Path) -> list[dict[str, object]]:
    archive = work / "C02-14_GML.zip"
    if not archive.exists():
        archive.write_bytes(fetch(C02_ZIP))
    xml_path = work / "C02-14-g.xml"
    if not xml_path.exists():
        with zipfile.ZipFile(archive) as bundle:
            member = next(name for name in bundle.namelist() if name.endswith("C02-14-g.xml"))
            xml_path.write_bytes(bundle.read(member))
    tree = ET.parse(xml_path)
    root = tree.getroot()
    gml = "{http://www.opengis.net/gml/3.2}"
    ksj = "{http://nlftp.mlit.go.jp/ksj/schemas/ksj-app}"
    xlink = "{http://www.w3.org/1999/xlink}href"
    points: dict[str, tuple[float, float]] = {}
    for point in root.iter(f"{gml}Point"):
        pos = point.find(f"{gml}pos")
        if pos is not None and pos.text:
            lat, lon = map(float, pos.text.split())
            points[point.attrib[f"{gml}id"]] = (lat, lon)
    ports = []
    for port in root.iter(f"{ksj}PortAndHarbor"):
        ref = port.find(f"{ksj}position")
        name = port.findtext(f"{ksj}portName", "").strip()
        admin = port.findtext(f"{ksj}administrativeAreaCode", "")
        point = points.get((ref.attrib.get(xlink, "") if ref is not None else "").lstrip("#"))
        pref = next((item for item, value in PREF_CODES.items() if value == admin[:2]), None)
        if point and pref in COASTAL_PREFS and name and 20 < point[0] < 47 and 120 < point[1] < 150:
            ports.append({"code": port.findtext(f"{ksj}portCode", ""), "name": name, "pref": pref,
                          "lat": point[0], "lon": point[1], "source": "mlit-c02"})
    return ports

def select_ports(existing, candidates, current_codes, harbor_candidates):
    selected: list[dict[str, object]] = []
    for pref in COASTAL_PREFS:
        # Long coastlines and island prefectures receive a denser baseline.
        target = 30 if pref in {"北海道", "東京都", "長崎県", "鹿児島県", "沖縄県"} else 24
        known = list(existing[pref])
        known_names = {normalize(item[0]) for item in known}
        pool = []
        for item in candidates:
            if item["pref"] != pref or item["code"] not in current_codes[pref]:
                continue
            normalized = normalize(str(item["name"]))
            point = (float(item["lat"]), float(item["lon"]))
            if not normalized or normalized in known_names:
                continue
            if any(distance_km(point, (lat, lon)) < 1.2 for _, lat, lon in known):
                continue
            pool.append(item)
        while len(known) < target and pool:
            def separation(item):
                point = (float(item["lat"]), float(item["lon"]))
                return min((distance_km(point, (lat, lon)) for _, lat, lon in known), default=9999)
            best = max(pool, key=lambda item: (separation(item), str(item["name"])))
            pool.remove(best)
            name = f"{best['name']}漁港周辺"
            known.append((name, float(best["lat"]), float(best["lon"])))
            known_names.add(normalize(name))
            selected.append(best)
        # Some prefectures have fewer current fishing ports than the display baseline.
        # Fill only with named national port records, maintaining geographic separation.
        harbor_pool = []
        for item in harbor_candidates:
            if item["pref"] != pref:
                continue
            normalized = normalize(str(item["name"]))
            point = (float(item["lat"]), float(item["lon"]))
            if not normalized or normalized in known_names:
                continue
            if any(distance_km(point, (lat, lon)) < 1.2 for _, lat, lon in known):
                continue
            harbor_pool.append(item)
        while len(known) < target and harbor_pool:
            def harbor_separation(item):
                point = (float(item["lat"]), float(item["lon"]))
                return min((distance_km(point, (lat, lon)) for _, lat, lon in known), default=9999)
            best = max(harbor_pool, key=lambda item: (harbor_separation(item), str(item["name"])))
            harbor_pool.remove(best)
            name = f"{best['name']}港周辺"
            known.append((name, float(best["lat"]), float(best["lon"])))
            known_names.add(normalize(name))
            selected.append(best)
    return selected

def write_output(selected):
    selected.sort(key=lambda item: (PREF_ORDER.index(str(item["pref"])), -float(item["lat"]), float(item["lon"])))
    lines = [
        "/* Generated from current Fisheries Agency fishing-port codes and MLIT C09/C02 positions.",
        " * A name is a representative coastal candidate, not permission to fish across the port. */",
        "window.NATIONWIDE_OFFICIAL_PORT_SEEDS = [",
    ]
    for item in selected:
        suffix = "漁港周辺" if item.get("source") == "jfa-c09" else "港周辺"
        name = str(item["name"]).replace("'", "’") + suffix
        lines.append(
            f"  ['{name}','{item['pref']}','{region_for(str(item['pref']))}','港',"
            f"{float(item['lat']):.5f},{float(item['lon']):.5f},'{item['source']}'],"
        )
    lines.append("];")
    OUTPUT.write_text("\n".join(lines) + "\n", encoding="utf-8")

def main():
    with tempfile.TemporaryDirectory(prefix="shiome-ports-") as temp:
        work = Path(temp)
        existing = existing_spots()
        current_codes = current_jfa_codes(work)
        candidates = c09_ports(work)
        harbor_candidates = c02_ports(work)
        selected = select_ports(existing, candidates, current_codes, harbor_candidates)
        write_output(selected)
        final_counts = {pref: len(existing[pref]) for pref in COASTAL_PREFS}
        for item in selected:
            final_counts[str(item["pref"])] += 1
        print(f"Generated {len(selected)} official coastal candidates")
        print("Minimum final count:", min(final_counts.values()))
        print("Below target:", {key: value for key, value in final_counts.items() if value < 24})

if __name__ == "__main__":
    main()
