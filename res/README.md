# Dog resources

This directory contains resource files that are required for the client-side pages:

- `main.css` is a CSS stylesheet (MIME type `text/css`)
- `gallery.js` is a JavaScript file (MIME type `text/javascript`)
- `gallery_min.js` is a minimized version of `gallery.js`

The `gallery_min.js` script is automatically generated from `gallery.js` by running it through the UglifyJS JavaScript mangler/compressor.  It is recommended that you use this minimized version in place of the full `gallery.js` since it is much smaller.

The recommended practice is to include `main.css` and `gallery_min.js` as global resources within the Yip CMS database.
