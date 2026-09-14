#!/usr/bin/env python3

"""Move the generated affiliation block ahead of a metadata abstract in DOCX."""

from __future__ import annotations

import argparse
from pathlib import Path

from docx import Document


def clean_text(value: str) -> str:
    return " ".join(value.replace("\xa0", " ").split())


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("input_docx", type=Path)
    parser.add_argument("output_docx", type=Path)
    args = parser.parse_args()

    document = Document(args.input_docx)
    body = document.element.body
    paragraphs = list(document.paragraphs)

    abstract_titles = [
        paragraph
        for paragraph in paragraphs
        if paragraph.style.name == "Abstract Title"
        and clean_text(paragraph.text) == "Abstract"
    ]
    affiliations = [
        paragraph
        for paragraph in paragraphs
        if clean_text(paragraph.text).startswith(
            "1 Department Health and Sports Sciences, TUM School of Medicine and Health,"
        )
        and "14 TUMCREATE Ltd., Singapore, Singapore" in clean_text(paragraph.text)
    ]
    correspondence = [
        paragraph
        for paragraph in paragraphs
        if clean_text(paragraph.text).startswith(
            "✉ Correspondence: Johannes Zauner <johannes.zauner@tum.de>"
        )
    ]

    if len(abstract_titles) != 1:
        raise RuntimeError(
            f"Expected one Abstract Title paragraph, found {len(abstract_titles)}"
        )
    if len(affiliations) != 1:
        raise RuntimeError(
            f"Expected one numbered affiliation paragraph, found {len(affiliations)}"
        )
    if len(correspondence) != 1:
        raise RuntimeError(
            f"Expected one correspondence paragraph, found {len(correspondence)}"
        )

    abstract_element = abstract_titles[0]._p
    affiliation_element = affiliations[0]._p
    correspondence_element = correspondence[0]._p
    body.remove(affiliation_element)
    body.remove(correspondence_element)
    abstract_index = body.index(abstract_element)
    body.insert(abstract_index, affiliation_element)
    body.insert(abstract_index + 1, correspondence_element)

    args.output_docx.parent.mkdir(parents=True, exist_ok=True)
    document.save(args.output_docx)


if __name__ == "__main__":
    main()

