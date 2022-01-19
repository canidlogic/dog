# Dog CMS Database Format

The database is stored in a SQLite database file, which has the following tables:

1. `vars`
2. `mime`
3. `template`
4. `resource`
5. `page`

## Unique name definition

A _unique name_ is a string key that is used to uniquely identify a record in various tables within this database.  Unique names have the following properties:

1. At least one character
2. At most 31 characters
3. Only visible US-ASCII characters
4. Only lowercase letters, digits, and underscore
5. Unique within the table they are used in

When unique names are received from a web client, they are _normalized_ before they are validated and looked up.  Normalization converts uppercase letters to lowercase and replaces any hyphen characters with underscores.

## Dog URL resolution

The last step of template processing in Dog CMS is to replace `dog://` URLs that are found anywhere in the resulting text.  Specifically, the following sequence is searched for:

    [[dog://

Anywhere this sequence of eight _case sensitive_ characters occurs is processed by the Dog CMS URL resolver.  If you need to include this sequence of eight characters without it being processed, you can escape it as follows:

    [[dog://!

This causes the Dog CMS URL resolver to replace this sequence of nine characters with the first eight characters in the output (without the trailing `!` exclamation mark).

In all other cases, the `dog://` URL must be enclosed in double square brackets:

    [[dog://...]]

Within the enclosed `...`, neither the sequence `[[` nor the sequence `]]` may occur.

The following subsections document what kind of special URLs are allowed in this `dog://` scheme.

### Dog config URLs

Dog URLs can be replaced by the value of any configuration value in the `vars` table by using the following syntax:

    [[dog://config/{varname}]]

In this case, the record from the `vars` table that has a key `{varname}` is retrieved and the whole dog URL reference is replaced by the value field in that record.  If the value field is NULL or no variable with that name exists in the table, the dog URL reference is replaced with an empty string.

### Dog resource URLs

Dog URLs can be replaced by the URL to a specific global or local resource by using one of the following syntaxes:

    [[dog://global/res/{resname}]]
    [[dog://page/{pageid}/res/{resname}]]
    [[dog://here/res/{resname}]]

The first syntax is used for global resources.  To use this syntax, a variable named `global_res_dir` must be defined in the `vars` table.  `{resname}` is appended to this variable value to form a URL to a global resource, and this resulting URL replaces the dog URL reference.

The second syntax is used to select a resource that is attached to a specific page.  First, the record for the page with ID `{pageid}` is looked up in the page table.  The page base field is taken from this record, and then `{resname}` is appended to this value to form a URL to a resource local to a specific page, and this resulting URL replaces the dog URL reference.

The third syntax may only be used when generating a specific page, and may __not__ be used when generating the catalog.  The `here` part of the URL is replaced with `page/{pageid}` where `{pageid}` is the ID of the page that is currently being generated, and then the dog URL is processed the same way as for the second syntax explained above.  This allows pages to refer to their resources without knowing their own page ID.

### Dog page URLs

Dog URLs can be replaced by the URL to a specific page by using one of the following syntaxes:

    [[dog://page/{pageid}]]
    [[dog://here]]

The first syntax is used to get the URL to a page with ID `{pageid}`.  It works by looking up the page record with that ID in the page table and then replacing the dog URL with the page URL field in that record.

The second syntax may only be used when generating a specific page, and may __not__ be used when generating the catalog.  The `here` part of the URL is replaced with `page/{pageid}` where `{pageid}` is the ID of the page that is currently being generated, and then the dog URL is processed the same way as for the first syntax explained above.  This allows pages to refer to themselves without knowing their own page ID.

## Vars table

The `vars` table is a simple key-value mapping that stores various configuration variables that do not fit in any of the other tables.  It has the following structure:

    CREATE TABLE vars(
      vid  INTEGER PRIMARY KEY,
      vkey TEXT UNIQUE NOT NULL,
      vval TEXT
    );

    CREATE UNIQUE INDEX vars_ikey ON vars(vkey);

The `vid` is the SQLite `rowid` alias field.  The `vkey` is the configuration variable name, which has the format of a unique name.  The `vval` is the value assigned to the configuration variable, which may be NULL.

## MIME table

The `mime` table simply defines mappings from the record ID field to string values holding a MIME type.  This is used because it is typical for only a small number of distinct MIME types to be used, so assigning each unique MIME type a number makes the database more efficient.  The table has the following structure:

    CREATE TABLE mime(
      mid   INTEGER PRIMARY KEY,
      mtype TEXT UNIQUE NOT NULL
    );

    CREATE UNIQUE INDEX mime_itype ON mime(mtype);

The `mid` is the SQLite `rowid` alias field, which also serves as the numeric identifier for the MIME type in the database.  The `mtype` is the actual MIME type text.  Whenever other tables need to include a MIME type value, they first look up whether the MIME type is already in this table.  If it is, they use the existing `mid` value.  Otherwise, they add the new MIME type and use the `mid` of that new value.  Therefore, the `mtype` field should have a unique value.  It also should obey the following guidlines:

1. At least one character
2. At most 255 characters
3. Only visible US-ASCII characters and space
4. First character is not space
5. Last character is not space

## Template table

The `template` table stores templates that are used to dynamically generate HTML pages.  These templates follow the syntax of the Perl `HTML::Template` library.  Additionally, after they have been transformed by `HTML::Template`, the results are run through the `dog://` URL resolution (see earlier).

...
