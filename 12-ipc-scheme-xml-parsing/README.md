# IPC Scheme XML Parsing Notes

This repository focuses on analysis of the organization of the International Patent Classification XML scheme file, focusing on the early release IPC 2027.01.

The primary structural XML tag of the IPC scheme, which encodes IPC classification hierarchy, is `<ipcEntry>` with four important attributes:

- `kind`
- `symbol`
- `endSymbol`
- `entryType`

The `<ipcEntry>` tag is functionally overloaded, with specific function determined by the values of the `kind` and `entryType` attributes.

The four special `kind` functions are:

| `kind` | `Description`                                                                                                                                                                                                                                                                                                                                  |
| :----: | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `"i"`  | *Subclass index* - found in the official PDF subclass files ([IPC 2027.01](https://wipo.int/classifications/data/ipc/ITSupport_and_download_area/20270101/pdf/scheme/full_ipc/en/)), such as [a01b.pdf](https://wipo.int/classifications/data/ipc/ITSupport_and_download_area/20270101/pdf/scheme/full_ipc/en/a01.pdf).                        |
| `"g"`  | *Guidance heading* - groups multiple main groups (`ipcEntry - entryType="K"`; e.g., "Ploughs" immediately before main group "3/00" or "Harrows" before "19/00" in the [a01b.pdf](https://wipo.int/classifications/data/ipc/ITSupport_and_download_area/20270101/pdf/scheme/full_ipc/en/a01.pdf)) or index symbols (`ipcEntry - entryType="I"`) |
| `"n"`  | Semi-structured note.                                                                                                                                                                                                                                                                                                                          |
| `"t"`  | *Subsection* title - found in table of contents of PDFs of full sections, e.g.  [ipc_en_a_full_ipc_20270101.pdf](https://wipo.int/classifications/data/ipc/ITSupport_and_download_area/20270101/pdf/scheme/full_ipc/en/ipc_en_a_full_ipc_20270101.pdf)                                                                                         |

All these special `<ipcEntry>` variants are leaf tags (they have other non-structural nested tags, but no `<ipcEntry>`). When parsing the IPC scheme XML, extract these tags (along with their contents) first and remove them from the XML tree. Note that the scope of these tags is determined by their `symbol` and `endSymbol` attributes, so saving the `symbol` attribute of their immediate parents is not necessary.

*Subsection* title `"t"` are the fewest and simplest to parse.

*Subclass index* `"i"` include hierarchical `<indexEntry>` and can be parsed by walking the `<indexEntry>` trees.

*Guidance heading* `"g"` again mix two functionally similar types and should be sorted into two groups after extraction. The `"g"` tags do not contain this type information. Instead, look for `<ipcEntry>` having `kind` not equal to one of `ignt` (that is look for a structural `<ipcEntry>`) with the same `symbol` attribute as in the `"g"` tag. If the target `entryType"K"` that `"g"` tag defines main group set heading; if the target `entryType="I"` that `"g"` tag defines index symbol set heading.
