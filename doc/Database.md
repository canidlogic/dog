# Dog CMS Database Format

The database is stored in a SQLite database file, which has the following tables:

1. `vars`
2. `page`
3. `mime`
4. `resource`
5. `embed`
6. `catalog`

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
      purl   TEXT NOT NULL
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

The `purl` field is the canonical URL used to refer to this page on the website.  If a variable in the `vars` table named `local_page_prefix` is defined, then this value is automatically prefixed to all `purl` field values to form the actual URLs to the pages.  See `DogURL.md` for further information.

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

The `resource` table stores all the resources that may be referenced through Dog URL resource links.  (See `DogURL.md` for further information.)  The table has the following structure:

    CREATE TABLE resource(
      rid   INTEGER PRIMARY KEY,
      rpage INTEGER
              REFERENCES page(pid)
                ON DELETE CASCADE
                ON UPDATE CASCADE,
      rname TEXT NOT NULL,
      rtime INTEGER NOT NULL,
      rcode TEXT UNIQUE NOT NULL,
      rtype INTEGER NOT NULL
              REFERENCES mime(mid)
                ON DELETE RESTRICT
                ON UPDATE CASCADE,
      rdata BLOB NOT NULL,
      UNIQUE(rpage, rname, rtime)
    );

    CREATE UNIQUE INDEX resource_imulti
      ON resource(rpage, rname, rtime DESC);
    CREATE INDEX resource_iname
      ON resource(rpage, rname);
    CREATE INDEX resource_ipage
      ON resource(rpage);

    CREATE UNIQUE INDEX resource_icode
      ON resource(rcode);
    CREATE INDEX resource_itype
      ON resource(rtype);

The `rid` is the SQLite `rowid` alias field.

When resources are referenced from Dog URLs, they are looked up with the page they belong to (or NULL for global resources), and a name that is unique within that page, or within the global context.  The page reference is stored in the `rpage` field (a foreign key into the `page` table) and the resource name is stored in the `rname` field.

Looking a resource up by page and name might select multiple records in the resource table if there are multiple versions of the same resource.  The `rtime` field is the number of seconds since midnight GMT at the start of January 1, 1970, up to the point at which the resource version was uploaded into the database.  If multiple records are selected during a lookup by page and name, the record with the most recent timestamp is selected, to choose the most recent version of a resource.

Once the appropriate resource record is located, the Dog URL must be transformed into a URL that the web client can use to request the specific version of the resource.  The details of how this is done is covered in `DogURL.md`.  However, the key point is that each specific version of each specific resource has a code that is unique across all resources in the resource table.  This unique code is stored in the `rcode` field.  The generated URL for the client will use this unique code, which can then be used to directly look up the appropriate resource for the client.

This scheme means that the resource at each URL is immutable, since newer versions will get a new URL with a different code.  This allows for simple, efficient cache control of resources on clients and proxies.

The recommended scheme for generating the unique code is to combine the `rpage`, `rname`, and `rtime` fields along with some random data, run this through an MD5 digest, and then use the base-64 representation, with `-` and `_` used for the last two digits to make the scheme URL-friendly, and without any padding `=` at the end.

The `rtype` field is a foreign key into the `mime` table, which determines the MIME type that is reported to the client when the resource is fetched.

Finally, the `rdata` field stores the actual binary data of the resource.

## Embed table

The `embed` table stores text content that may be embedded using the Dog URL scheme for text embedding.  (See `DogURL.md` for further information.)  The table has the following structure:

    CREATE TABLE embed(
      eid   INTEGER PRIMARY KEY,
      epage INTEGER
              REFERENCES page(pid)
                ON DELETE CASCADE
                ON UPDATE CASCADE,
      ename TEXT NOT NULL,
      eproc INTEGER NOT NULL,
      etext TEXT NOT NULL,
      UNIQUE(epage, ename)
    );

    CREATE UNIQUE INDEX embed_imulti ON embed(epage, ename);
    CREATE INDEX embed_ipage ON embed(epage);

The `eid` is the SQLite `rowid` alias field.

`epage` references the parent page this embed resource belongs to, or NULL if this is a global embed resource.  `ename` is the name of this resource.  The name should follow the name format defined earlier.  For embeds attached to a specific page, the name must be unique within all embeds for that page, while global embed names must be unique among all global embeds.

`eproc` is an integer value that defines what kind of processing is performed on the text.  The following values are possible:

- `0` : literal text
- `1` : Dog URL processing
- `2` : template processing
- `3` : template and Dog URL processing

When both Dog URL and template processing are selected at the same time, template processing always is done first.

Dog URL processing is actually always performed on the text.  For `eproc` codes `0` and `2`, all character sequences `[[dog://` that are found are replaced by the escape `[[dog://!` which means that when Dog URL processing is performed, you get the original text again.

Template processing uses the Perl `HTML::Template` module, with special variables set up.  See `PageTemplate.md` for further information.

## Catalog table

The `catalog` table contains pre-built catalog pages.  The contents of this table can be derived entirely from the rest of the database, so this is properly a cache table rather than a data table.  Caching the generated catalog pages means that they don't have to be regenerated from scratch each time they are requested.  However, it also means that this table may need to be rebuilt any time the database changes.

The catalog table has the following structure:

    CREATE TABLE catalog(
      cid   INTEGER PRIMARY KEY,
      cnum  INTEGER UNIQUE NOT NULL,
      ctext TEXT
    );

The `cid` is the SQLite `rowid` alias.  The `cnum` is the catalog page number, where 1 is the first catalog page.  `ctext` is the fully generated text of the catalog page.  No Dog URL or template processing is needed here, so this generated page content can be echoed as-is.

If `ctext` is NULL, it means that the catalog page exists, but there was an error generating it.  HTTP status 500 "Internal Server Error" can be returned to clients that request a catalog page with a NULL `ctext` field.

If a catalog page is requested but no record in this table has a `cnum` matching the requested page number, then the catalog page does not exist and HTTP status 404 "Not Found" can be returned to clients.
