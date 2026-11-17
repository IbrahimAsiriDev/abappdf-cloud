# abapPDF Cloud

PDF form designer and native PDF renderer for **ABAP Cloud** (SAP BTP ABAP environment and ABAP Cloud development on S/4HANA), written in ABAP for Cloud Development.

This is the ABAP Cloud edition of [abapPDF](https://github.com/IbrahimProg/abappdf). The classic ABAP (on-premise, SAP GUI) edition lives in that repository.

## Features

- **Web designer** served by the system itself: form list, drag and drop layout, tables, images, QR codes and Code 128 barcodes, versions.
- **Native PDF engine** in ABAP Cloud: A4 and other page sizes, headers and footers, tables over several pages.
- **Arabic support** with an embedded subset of Noto Naskh Arabic.
- **Template binding**: fields, loops, conditions, totals, number and date formats.
- **RAP demo**: a Fiori elements travel list with a *Print PDF* action that stores the PDF.
- **Optional Gotenberg** engine through a BTP destination.

## Installation

1. In ABAP Development Tools create package `ZABAPPDF_CLOUD` (ABAP language version *ABAP for Cloud Development*). On the SAP BTP trial, use `ZLOCAL` as super package and software component.
2. Link this repository to the package with the abapGit plug-in for ADT and pull.
3. Activate all objects (*Ctrl+Shift+F3*): the abapGit plug-in for ADT pulls objects without activating them.
4. **Create the HTTP service by hand.** abapGit does not transport HTTP services, and the designer and the HTTP API need one: create `ZABAPPDF_HTTP` with handler class `ZCL_ABAPPDF_HTTP` (*New > Other ABAP Repository Object > Connectivity > HTTP Service*). The editor shows its URL; open it in a browser. On SAP BTP the service works right away, without *Publish Locally*.
5. For the RAP demo: create service binding `ZUI_ABAPPDF_TRAVEL_O4` (OData V4 - UI) for service definition `ZUI_ABAPPDF_TRAVEL` and publish it. The demo uses the flight reference data (`/DMO/TRAVEL`, `/DMO/BOOKING`).

**On-premise (S/4HANA 2022 or higher)**: an HTTP service created in ADT gets no SICF node of its own; it runs below `/sap/bc/http/sap`. Two more steps are needed:

- In transaction `UCON_HTTP_SERVICES`, search `ZABAPPDF_HTTP` and choose **Activate**.
- In transaction `SICF`, check that the nodes `/sap/bc/http` and `/sap/bc/http/sap` are active. If they are inactive (grey), as on the ABAP Platform trial, activate them (this node only, not the subtree). Otherwise every service below them answers *403 Forbidden*.

## Getting started

1. Open `https://<your system>/sap/bc/http/sap/zabappdf_http` in a browser. The form list (home screen) shows the demo forms `ZPDF_TRAVEL` and `ZPDF_TRAVEL_AR` (Arabic, right to left), which are added on the first visit.
2. Open `ZPDF_TRAVEL` and choose **Render PDF**. The preview reads a real travel from `/DMO/TRAVEL`.
3. In the travel app of the service binding, select a travel and choose **Print PDF**. The PDF is stored with the travel and opens from the **PDF** column. Users who log on in Arabic get `ZPDF_TRAVEL_AR`.

Both demo forms ship in the class `ZCL_ABAPPDF_DEMO` (sources: `forms/ZPDF_TRAVEL.xml` and `forms/ZPDF_TRAVEL_AR.xml`). **Print PDF** works before the first visit too; it then prints with this built-in copy. A demo form you delete is not added again.

## Use it in your code

```abap
DATA(lv_pdf) = zcl_abappdf_api=>render_pdf(
  iv_form_id = 'ZPDF_TRAVEL'
  is_data    = ls_doc ).
```

`ls_doc` is any structure. Its component names are the template tags: `ls_doc-travel_id` fills `{{TRAVEL_ID}}`, and a table component `bookings` is repeated with `{{#each BOOKINGS}}`. `ZCL_ABAPPDF_RAP=>PRINT` is a complete example that reads a travel and its bookings.

## Live data in the designer

The preview data of a form can come from the system instead of fixed sample JSON:

```json
{ "source": "ZCL_ABAPPDF_TRAVEL", "key": "00000001" }
```

A source is any global class that implements `ZIF_ABAPPDF_DATA` and can be created without parameters. Its `READ` method gets the key and returns the data as JSON. Two sources are included: `ZCL_ABAPPDF_TRAVEL` (also available as `/DMO/TRAVEL`) and `ZCL_ABAPPDF_INVOICE`. A source runs with the user of the designer, so it must check that user's authorization for the data it returns.

## Template syntax

| Syntax | Meaning |
|---|---|
| `{{FIELD}}` | Value of a field, HTML-escaped |
| `{{#each ITEMS}} ... {{/each}}` | Repeat for every row of a table |
| `{{ROW}}` | Row number inside `{{#each}}` |
| `{{#if FIELD}} ... {{else}} ... {{/if}}` | Condition; also `ROW_EVEN` and `ROW_ODD` |
| `{{sum ITEMS.AMOUNT}}`, `{{count ...}}`, `{{avg ...}}`, `{{min ...}}`, `{{max ...}}` | Totals |

`data-fmt` formats a bound value: `#,##0.00`, `#.##0,00`, `AR#,##0.00`, `YYYY-MM-DD`, `DD/MM/YYYY`. An unknown field raises `ZCX_ABAPPDF` with the text `Unknown template field: <name>`.

## HTTP API

The designer uses these paths below the service URL. They can also be called from other clients.

| Method | Path | Result |
| --- | --- | --- |
| GET | `/forms` | id, description, package, version, changedAt |
| POST | `/forms` | create a form from `{id, description, package}` |
| GET | `/forms/{id}` | active version |
| PATCH | `/forms/{id}` | name, package and description |
| DELETE | `/forms/{id}` | form and every version |
| GET | `/forms/{id}/versions` | version, changedBy, changedAt |
| GET | `/forms/{id}/versions/{version}` | that stored version |
| POST | `/forms/{id}/versions` | next version; older versions stay |
| POST | `/forms/{id}/render` | JSON business data in, `application/pdf` out |

Requests other than `GET` must send header `x-csrf-token` with the token that a `GET` returns. Cross-origin requests are allowed from the host that served the page, from `localhost`, `127.0.0.1` and `[::1]`, and from one extra origin in setting `CORS_ORIGIN` of table `ZABAPPDF_CONF`.

## Settings (table `ZABAPPDF_CONF`)

| Key | Value |
|---|---|
| `PDF_ENGINE` | `ABAP` (default) or `GOTENBERG` |
| `GOTENBERG_DESTINATION` | BTP destination of the Gotenberg server |
| `CORS_ORIGIN` | one extra browser origin for the HTTP API |

## Development

- `web/designer.html` is the source of the designer page. `ZCL_ABAPPDF_UI` holds the same page as base64 chunks.
- The demo forms in `ZCL_ABAPPDF_DEMO` are the exports in `forms/`.
- Unit tests: `ZCL_ABAPPDF_BINDER`, `ZCL_ABAPPDF_RENDERER` and `ZCL_ABAPPDF_CODES`.

## License

[MIT](LICENSE).

## Credits

Arabic text is printed with a subset of [Noto Naskh Arabic](https://github.com/notofonts/arabic) by the Noto Project Authors, licensed under the [SIL Open Font License 1.1](OFL.txt).
