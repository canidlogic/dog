# Page generation variables

Dynamic generation of pages is always in two stages.  The first stage runs the HTML template through the `HTML::Template` module.  The second stage replaces `dog://` URLs in the generated output to form the final result.  The `dog://` URL replacement is described in the `DogURL.md` document.  This document describes HTML template generation.

For the syntax of HTML templates, see the documentation of the Perl `HTML::Template` module.

This document describes the variables that are made available for use within HTML templates.  First, a set of automatic variables are defined.  Second, any variables from the page's JSON metadata are defined.  Variables in the page's JSON metadata may overwrite the automatic variable definitions if they have the same name.

## Automatic variables

The following two automatic variables are declared for every template:

- `is_catalog` : 1 if this is a catalog page, 0 for content
- `has_prev` : 1 if there is a previous page, 0 if not
- `has_next` : 1 if there is a next page, 0 if not

The `is_catalog` variable is used to distinguish within the template whether this is a catalog page or a content page.  This allows the same template to be used for both catalog pages and content pages, though this does not have to be the case.

For the dynamic generation of catalog HTML pages, "previous" and "next" refer to pages in the catalog.  `has_prev` is one, except for the first page of the catalog.  `has_next` is one, except for the last page of the catalog.

For the dynamic generation of content HTML pages, "previous" and "next" refer to surrounding pages in the chronology.  `has_prev` and `has_next` will both be zero for pages that are not part of the chronological ordering (their pin-class is -1), and both will also be zero if there is only a single page in the chronological ordering.  In all other cases, `has_prev` is one, except for the first page in the chronology, and `has_next` is one, except for the last page in the chronology.

The default chronological ordering is reverse chronology, where the most recent page is first and the oldest page is last.  If the variable `chronology` is defined in the `vars` table of the Dog CMS database, then it chooses the chronology to use.  The only valid values are `forward` and `reverse` where `forward` means the oldest page is first and `reverse` is the default where the newest page is first.  (The chronology in content pages links keeps pinned pages in their regular chronological order.)

If `has_prev` is one, then the following variables will also be defined:

- `prev_url` : the URL to the previous page
- `prev_data` : previous page's metadata (see below)

The `prev_data` field for catalog HTML pages will simply be an integer value that has the page number of the previous page, where one is the first page.  For content pages, the `prev_data` field will be an array of exactly one object that has all the JSON metadata for the previous page.  To use the `prev_data` field in the HTML template, use a `<TMPL_LOOP>` -- which will only run once -- and within that single loop iteration, you have access to the metadata values for the previous page.

For catalog HTML pages, `prev_url` depends on whether it is referencing the first page of the catalog.  If it is, then its value will be the value of the `catalog_start` variable in the `vars` table, which must be defined.  Otherwise, its value is the value of the `catalog_page` variable in the `vars` table, with the decimal page number appended to it.

For content HTML pages, `prev_url` will be a `dog://` URL reference to the appropriate page.  During dog URL replacement, this URL will then be replaced with the appropriate page URL.

If `has_next` is one, then the following variables will also be defined:

- `next_url` : the URL to the next page
- `next_data` : the next page's metadata (see below)

These two variables work the same way as the corresponding `prev_` variables.

### Catalog automatic variables

For the dynamic generation of catalog pages, the automatic variables described previously will be available, as well as special automatic variables specific to catalog pages only.  This section describes the variables specific to catalog pages only.

The following variable is always available to catalog pages:

- `catalog_data` : the catalog item array

The catalog data array represents all the catalog items that should appear on the current catalog page, in the order they are supposed to appear.  Each catalog data array element has the following two fields:

1. `item_url` : the URL of the item
2. `item_data` : the metadata of the item

The `item_url` is set to a `dog://` URL reference to the appropriate page.  During dog URL replacement, this URL will then be replaced with the appropriate page URL.

The `item_data` URL is an array of exactly one object that has all the JSON metadata for the page in question.  To use this data in the HTML template, use an inner `<TMPL_LOOP>` -- which will only run once -- and within that single loop iteration, you have access to the metadata values for the page that is being referenced.

...
