"""Validate the module's documentation contract and render CWL Markdown."""

import argparse
from pathlib import Path
from urllib.parse import urlsplit

import yaml
from schema_salad.fetcher import DefaultFetcher


class PublishedSchemaFetcher(DefaultFetcher):
    """Permit the approved published EOAP schemas as the dependency contract."""

    def fetch_text(self, url: str, content_types: list[str] | None = None) -> str:
        if urlsplit(url).scheme in {"http", "https"} and url.split("#")[0] not in {
            "https://raw.githubusercontent.com/eoap/schemas/main/ogc.yaml",
            "https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml",
        }:
            raise RuntimeError("Only approved published EOAP schemas may be fetched")
        return super().fetch_text(url, content_types)


def check(value: object, path: Path) -> None:
    if isinstance(value, dict):
        assert "$include" not in value, f"{path}: external include"
        if "$import" in value:
            assert value["$import"] in {
                "https://raw.githubusercontent.com/eoap/schemas/main/ogc.yaml",
                "https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml",
            }, f"{path}: unapproved schema import"
        for child in value.values():
            check(child, path)
    elif isinstance(value, list):
        for child in value:
            check(child, path)


def render(path: Path) -> str:
    document = yaml.safe_load(path.read_text())
    assert document["cwlVersion"] == "v1.2", path
    for field in ("s:softwareVersion", "s:codeRepository", "s:license", "s:author"):
        assert document.get(field), f"{path}: missing {field}"
    assert document["s:codeRepository"] == "https://github.com/eoap/how-to", path

    check(document, path)
    lines = [
        f"# {path.stem}",
        "",
        f"Repository: {document['s:codeRepository']}",
        "",
        f"Version: {document['s:softwareVersion']}",
        "",
        f"License: {document['s:license']}",
        "",
    ]
    for author in document["s:author"]:
        assert author.get("s:name") and author.get("s:email"), f"{path}: incomplete author"
        lines.extend([f"Author: {author['s:name']} ({author['s:email']})", ""])
    for process in document.get("$graph", [document]):
        assert process.get("label") and process.get("doc"), f"{path}: missing process description"
        lines.extend([f"## {process['label']}", "", process["doc"], ""])
        for group in ("inputs", "outputs"):
            lines.extend(
                [
                    f"### {group.capitalize()}",
                    "",
                    "| Name | Type | Description |",
                    "| --- | --- | --- |",
                ]
            )
            ports = process.get(group, {})
            ports = ports.items() if isinstance(ports, dict) else ((p["id"], p) for p in ports)
            for name, port in ports:
                assert (
                    isinstance(port, dict)
                    and port.get("type")
                    and port.get("label")
                    and port.get("doc")
                ), f"{path}: undocumented {name}"
                description = port["doc"].replace("\n", " ").replace("|", "\\|")
                kind = str(port["type"]).replace("|", "\\|")
                lines.append(f"| {name} | `{kind}` | {description} |")
            lines.append("")
        requirements = process.get("requirements", {})
        schemas = (
            requirements.get("SchemaDefRequirement", {}).get("types", [])
            if isinstance(requirements, dict)
            else []
        )
        for schema in schemas:
            if "$import" in schema:
                lines.extend([f"Shared schema: {schema['$import']}", ""])
                continue
            lines.extend(
                [
                    f"### Type `{schema['name']}`",
                    "",
                    "```yaml",
                    yaml.safe_dump(schema, sort_keys=False).rstrip(),
                    "```",
                    "",
                ]
            )
    return "\n".join(lines)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--validate",
        action="store_true",
        help="Also validate isolated CWL, allowing the approved OGC schema import",
    )
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    import tempfile

    output: Path = args.output or Path(tempfile.mkdtemp(prefix="howto-cwl-docs-"))
    root = Path(__file__).resolve().parents[1]
    for path in sorted(root.rglob("*.cwl")):
        if any(part.startswith(".") for part in path.relative_to(root).parts):
            continue
        markdown = render(path)
        if args.validate:
            import shutil
            import tempfile

            from cwltool.context import LoadingContext
            from cwltool.main import main

            context = LoadingContext()
            context.fetcher_constructor = PublishedSchemaFetcher
            with tempfile.TemporaryDirectory() as isolated:
                target_cwl = Path(isolated) / path.name
                shutil.copy(path, target_cwl)
                assert main(["--validate", str(target_cwl)], loadingContext=context) == 0, path
        target = output / path.relative_to(root).with_suffix(".md")
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(markdown)
        print(f"Validated and rendered {path.relative_to(root)}")
