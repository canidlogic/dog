# Dog template variables

This document describes the custom template variables that must be set up in the Yip CMS before the Dog (meta)templates in the `template` directory can function properly.

(Remember that the Dog metatemplates will also need to be compiled with `dogmeta.pl` before they can be used, and that the Dog preprocessor must be installed in the Yip deployment!)

## Localization variables

The localization variables are text strings used within the templates.  They are stored in template variables so that it is easy to translate the templates into other languages just by setting the proper localized strings for these variables.  All the following must be defined:

- `loc_archives`

On the catalog page, the string used in the header for the archive list.  Suggested value in English is `Archives`

- `loc_back_catalog_main` 

On archive pages, the string used in the link leading back to the main catalog page.  Suggested to enclose this string within some kind of brackets.  Suggested value in English is `» Back to main catalog «`

- `loc_back_catalog`

On gallery pages, the string used in the link leading back to the main catalog page.  Suggested to enclose this string within some kind of brackets.  Suggested value in English is `» Back to catalog «`

- `loc_back_archive`

On gallery pages, the string used in the link leading back to an archive page.  Suggested to enclose this string within some kind of brackets.  Suggested value in English is `» Back to archive «`

- `loc_gallery_empty`

On gallery pages, the string that is displayed if there are no pictures in the gallery.  Suggested value in English is `Gallery is empty`

## Site variables

The site variables define properties of the site on a whole.  The following must be defined:

- `site_lang`

The language code to declare in the `<html>` tag on each page.  For English, you would set this to `en`

- `site_name`

The name of this Dog photo album site, which is used as the name of the site on all generated pages.

## URI variables

The URI variables define the paths to various resources that will be used within generated links.  The following must be defined:

- `uri_css`

The path to the `main.css` resource.  If you are following the recommended approach of serving this CSS file as a global resource, this path should be the path to the specific Yip global resource holding the CSS file.  This should be served as a `text/css` file, and the data contained within should be the `main.css` file in the `res` directory.

- `uri_catalog`

The path to the main catalog page.  This should be the path to the Yip catalog page.

- `uri_gallery`

The path prefix for a gallery page.  To get a link to a gallery page with a certain unique ID code, the six decimal digits of the unique ID code will be suffixed directly to this `uri_gallery` variable.  This variable should therefore be the path to a Yip post page, excluding the six digits of the post unique ID.

- `uri_archive`

The path prefix for an archive page.  To get a link to an archive page with a certain unique ID code, the six decimal digits of the unique ID code will be suffixed directly to this `uri_archive` variable.  This variable should therefore be the path to a Yip archive page, excluding the six digits of the archive unique ID.

- `uri_photo`

The path prefix for a local attachment.  To get a link to a photo file with a certain attachment index within a gallery with a certain unique ID code, take this `uri_photo` variable, suffix the six decimal digits of the unique ID code of the gallery, and then suffix the four decimal digits of the attachment index.  This variable should therefore be the path to a Yip local resource, excluding the ten digits used to identify the post and attachment index.
