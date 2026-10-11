"""Rewrite only the How-To runtime reference in standalone application documents."""


def replace_processing_image(value: object, image: str) -> int:
    """Preserve imported schemas, module-owned types and other runtime images."""
    count = 0
    if isinstance(value, dict):
        pull = value.get("dockerPull")
        if isinstance(pull, str) and pull.startswith("ghcr.io/eoap/how-to/rio@sha256:"):
            value["dockerPull"] = image
            count += 1
        for child in value.values():
            count += replace_processing_image(child, image)
    elif isinstance(value, list):
        for child in value:
            count += replace_processing_image(child, image)
    return count
