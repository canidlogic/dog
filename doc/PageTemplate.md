# Page generation by template

The Dog URL syntax described in `DogURL.md` allows embedded text to be processed through templates.  This document describes how templates work.

The basic template syntax is defined in the documentation for the Perl `HTML::Template` module, which can be viewed [here](https://metacpan.org/pod/HTML::Template).

The only aspect of templates that is not defined in that documentation is which specific variables are available for use by templates.  This document describes the specific variables available to templates when running in the Dog CMS text engine.

## State variables

The following two variables are always available in every context, to allow a template to determine what it is being used for:

- `is_catalog` : 1 if this is a catalog page, 0 for content
- `has_here` : 1 if a current page is in context, 0 if not

If `is_catalog` is zero, then `has_here` is always one.  `has_here` may only be zero if `is_catalog` is one.  This leads to the following possible states:

1. Catalog page (`is_catalog` and NOT `has_here`)
2. Item listing (`is_catalog` and `has_here`)
3. Page content (`has_here` and NOT `is_catalog`)

For catalog pages, the HTML fragment for each catalog item that is listed on the page is first generated, separately for each item.  This is the _item listing_ state.  Then, all the catalog item fragments are assembled on a single catalog page.  This is the _catalog page_ state.

For content pages, the _page content_ state is used when generating the page.

The `has_here` variable refers to whether a "current page" is in context, which allows special `here` syntaxes to be used with Dog URLs.  See `DogURL.md` for further information about the "current page" concept.

## Catalog page variables

In the _catalog page_ state, the following variables are available in addition to the state variables that are always available:

- `has_prev` : 1 if there is a previous catalog page, 0 if not
- `has_next` : 1 if there is a next catalog page, 0 if not
- `page_num` : the catalog page number as a string
- `listing` : array of generated catalog listings
- `jumps` : array of jump links

The `has_prev` and `has_next` variables allow a template to determine whether this is the first catalog page, the last catalog page, or a catalog page in the middle.  The `page_num` is the one-based catalog page number as a string, for listing the page number if necessary.

The `listing` variable is intended for use within a `<TMPL_LOOP>`.  You can also use the variable in `<TMPL_IF>` and `<TMPL_UNLESS>` to check whether there is at least one element in this array or whether the array is empty.  Each element is an object that has a property `html` which maps to a string value that is the generated HTML for the catalog element.

The `jumps` variable is intended for making a list of links to different catalog pages, and can be used within a `<TMPL_LOOP>`.  This list always has at least one element.  Each element has a property named `skip` which is one if this element represents a `...` that doesn't link anywhere, or zero if this is a page link.  Neither the first nor last element will have `skip` set to one, and no two elements in a row will both have `skip` set to one.  If `skip` is zero, then there will also be properties `num` and `current` where `num` is a string containing the one-based page number of the catalog for this entry, and `current` is one if this is the current catalog page or zero if not.  If `current` is zero, then there is also a property `link` containing a link to the relevant catalog page.

The `jumps` variable allows a list of links like this:

    [1] [2] ... [25] [26] >27< [28] [29] ... [254] [255]

    jumps array for this list:
    [
      {skip: 0, num:   "1", current: 0, link: ...},
      {skip: 0, num:   "2", current: 0, link: ...},
      {skip: 1},
      {skip: 0, num:  "25", current: 0, link: ...},
      {skip: 0, num:  "26", current: 0, link: ...},
      {skip: 0, num:  "27", current: 1},
      {skip: 0, num;  "28", current: 0, link: ...},
      {skip: 0, num;  "29", current: 0, link: ...},
      {skip: 1},
      {skip: 0, num; "254", current: 0, link: ...},
      {skip: 0, num; "255", current: 0, link: ...}
    ]

These jump lists are constructed according to a _sliding window_ around the current page, as well as _bumpers_ at the start and end of the list.  The example list above has the following parameters:

    jump_window_before = 2
    jump_window_after  = 2

    jump_bumper_start  = 2
    jump_bumper_end    = 2

`jump_window_before` means that you should always display at least this many pages in the list before the current page, if possible.  `jump_window_after` means that you should always display at least this many pages in the list after the current page, if possible.  `jump_bumper_start` means that you should always display at least this many pages at the start of the list, if possible.  `jump_bumper_end` means that you should always display at least this many pages at the end of the list, if possible.  The current page is always displayed, and each of these `jump` parameters must always be at least one.

These `jump` parameters may be defined in the `vars` table.  If not defined, they default to the value two.

If the `has_prev` variable is one, then the following variables are also defined:

- `prev_num` : the one-based number of the previous catalog page, as a string
- `prev_link` : the link to the previous catalog page

If the `has_next` variable is one, then the following variables are also defined:

- `next_num` : the one-based number of the next catalog page, as a string
- `next_link` : the link to the next catalog page

By default, each catalog page has at most 20 items in its listing.  If the `catalog_capacity` variable is defined in the `vars` table, then it can change this default setting to the given integer value, which must be at least one.

Only pages that have a pin-class that is zero or greater will be included in the catalog.  Within the catalog, pages are always sorted first in descending order of pin-class, so that pinned pages will always appear at the start of the catalog.  Within each pin-class (including the pin-class of zero), pages are by default ordered in reverse chronological order, with more recent pages first.  However, if the `chronology` variable is defined in the `vars` table, then it must have a value either of `forward` or `reverse` which selects either forward chronology (oldest pages first) or reverse chronology (newest pages first).

...
