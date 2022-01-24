# Dog CMS Database Format

The database is stored in a SQLite database file, which has the following tables:

1. `vars`
2. `page`
3. `mime`
4. `resource`
5. `template`
6. `embed`

## Name definition

A _name_ is a string key that is used to identify a record in various tables within this database.  Names have the following properties:

1. At least one character
2. At most 31 characters
3. Only visible US-ASCII characters
4. Only lowercase letters, digits, and underscore

When names are received from a web client, they are _normalized_ before they are validated and looked up.  Normalization converts uppercase letters to lowercase and replaces any hyphen characters with underscores.

## Vars table

The `vars` table is a simple key-value mapping that stores various configuration variables that do not fit in any of the other tables.  It has the following structure:

    CREATE TABLE vars(
      vid  INTEGER PRIMARY KEY,
      vkey TEXT UNIQUE NOT NULL,
      vval TEXT
    );

    CREATE UNIQUE INDEX vars_ikey ON vars(vkey);

The `vid` is the SQLite `rowid` alias field.  The `vkey` is the configuration variable name, which has the name format defined earlier and must be unique within the table.  The `vval` is the value assigned to the configuration variable, which may be NULL.

## Page table

The `page` table stores all the content pages within the Dog CMS.  It has the following structure:

    CREATE TABLE page(
      pid    INTEGER PRIMARY KEY,
      pname  TEXT UNIQUE NOT NULL,
      ptime  INTEGER UNIQUE NOT NULL,
      pclass INTEGER NOT NULL,
      pjson  TEXT NOT NULL,
      plist  TEXT NOT NULL,
      ppage  TEXT NOT NULL,
      purl   TEXT NOT NULL,
      pbase  TEXT NOT NULL
    );

    CREATE UNIQUE INDEX page_iname ON page(pname);
    CREATE UNIQUE INDEX page_itime ON page(ptime);
    CREATE INDEX page_iclass ON page(pclass);
    CREATE UNIQUE INDEX page_rchrono ON page(pclass DESC, ptime DESC);
    CREATE UNIQUE INDEX page_fchrono ON page(pclass DESC, ptime ASC);

The `pid` is the SQLite `rowid` alias field.  The `pname` is the name of the page, which must follow the name format defined earlier and be unique within the table.  The `ptime` is the timestamp of the page, which is the number of seconds that have elapsed since midnight GMT at the start of January 1, 1970.

The `pclass` is the pin-class of the page.  Regular pages have a pin-class of zero.  If the pin-class is -1, then the page is unlisted and not part of the catalog.  If the pin-class is greater than zero, then the page is pinned.  Pinned pages are sorted so that pages with a greater pin-class come earlier in the sequence.

The `pjson` field stores a JSON representation of the page data.  See `PageTemplate.md` for further information about how this JSON data can be accessed within templates and what its format must be like.

The `plist` and `ppage` fields store the HTML content used to render the page in catalog listings and content pages, respectively.  `plist` should be an HTML fragment that will be included within a catalog page, while `ppage` should be a complete HTML page.  Dog URL replacement is done to both of these values to render them.  See `DogURL.md` for further information.

The `purl` field is the canonical URL used to refer to this page on the website.  If a variable in the `vars` table named `local_page_prefix` is defined, then this value is automatically prefixed to all `purl` field values to form the actual URLs to the pages.

The `pbase` field is the canonical base URL that is used to construct URLs to resources specific to this page.  If a variable in the `vars` table named `local_res_prefix` is defined, then this value is automatically prefixed to all `pbase` field values to form the actual URL base for the resources.

See `DogURL.md` for further information about how the `purl` and `pbase` fields are used.

## MIME table

The `mime` table defines a mapping from resource type names to MIME types corresponding to those resources.  This is used because it is typical for only a small number of distinct MIME types to be used, so it is more efficient to link to records in this table than to repeat the same MIME type string over and over.  Also, this allows the MIME type for a particular named resource type to be easily updated across the whole website just by updating this table.

The table has the following structure:

    CREATE TABLE mime(
      mid   INTEGER PRIMARY KEY,
      mkey  TEXT UNIQUE NOT NULL,
      mtype TEXT NOT NULL
    );

    CREATE UNIQUE INDEX mime_ikey ON mime(mkey);

The `mid` is the SQLite `rowid` alias field.  The `mkey` is the name of the resource type, which must follow the name format defined earlier and be unique within the table.  The `mtype` is the actual MIME type text.  It is possible for multiple different resource type names to map to identical MIME type text fields.

The `mtype` field should obey the following guidlines:

1. At least one character
2. At most 255 characters
3. Only visible US-ASCII characters and space
4. First character is not space
5. Last character is not space

## Resource table

The `resource` table stores all the resources that may be referenced through Dog URL resource links.  (See `DogURL.md` for further information.)

...

## Template table

The `template` table stores templates that are used to dynamically generate HTML pages.  These templates follow the syntax of the Perl `HTML::Template` library, using the template variables defined in `PageVar.md`.  Additionally, after they have been transformed by `HTML::Template`, the results are run through the `dog://` URL resolution (see `DogURL.md`).

...
