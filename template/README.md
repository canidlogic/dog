# Dog templates

This directory contains Dog templates and Dog metatemplates.  The three provided files are as follows:

- `archive.meta` is a _metatemplate_ for the Yip archive template
- `catalog.meta` is a _metatemplate_ for the Yip catalog template
- `gallery.tmpl` is the Yip post template

The metatemplates (end with file extension `.meta`) must be compiled first with the `dogmeta.pl` script, in order to properly localize them.  Only after they have been compiled with `dogmeta.pl` can they be uploaded to the Yip CMS.

The `gallery.tmpl` does not need any metatemplate processing, and it can be directly uploaded to the Yip CMS.

See the `DogVars.md` documentation file in the `doc` directory for what special template variables must be defined in Yip before these templates can work properly.  Also note that the Dog preprocessor plug-in for Yip must be installed in the Yip deployment for the `gallery.tmpl` to work correctly.
