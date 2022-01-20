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

The `template` table stores templates that are used to dynamically generate HTML pages.  These templates follow the syntax of the Perl `HTML::Template` library, using the template variables defined in `PageVar.md`.  Additionally, after they have been transformed by `HTML::Template`, the results are run through the `dog://` URL resolution (see `DogURL.md`).

...
