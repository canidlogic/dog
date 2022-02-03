# Transaction format

All Dog CMS database tables except for `user` are edited using a special MIME-based transaction format.  One whole transaction is stored within a multipart MIME message, which is then used to update the Dog CMS database in a single database transaction.  Using multiple MIME allows resource files to be easily embedded within the transaction message.

The whole transaction file is a MIME message in `multipart/mixed` format.  Operations within the transaction are performed in the sequential order that they appear within the MIME message.  The first part of each operation is always a `text/plain` part that contains the command to perform and an index of attachments.  The second part of each operation is always an `application/json` part that contains the data for the operation.  The second part is followed by a sequence of zero or more attachment parts of `application/octet-stream` type.  The number of attachments must match the number of attachments specified in the attachment index from the first part of the command.

## Command part format

The command part is a `text/plain` part that always appears as the first part of each operation within the transaction.  The very first part in the transaction MIME message must be a command part.

The first line of the command part selects a command to perform for this operation.  The following commands are supported:

- `SET VARIABLES`
- `CREATE PAGE`
- `EDIT PAGE`
- `DROP PAGE`
- `SET TYPES`
- `SET GLOBAL RESOURCES`
- `SET GLOBAL EMBEDS`
- `RENAME`

The second line of the command part contains an unsigned decimal integer that counts the number of attachments to this operation within the MIME message.  It may be zero if there are no attachments.

After the second line, there are _n_ additional lines, where _n_ is the number of attachments defined on the second line.  Each line contains a name for the attachment that is unique within this operation.  The name is a case-insensitive sequence of one or more ASCII alphanumerics and underscores.  The attachment name is only used for referring to the attachment within this operation; the name is not actually stored in the Dog CMS database.

Attachments are not added to the Dog CMS database unless they are referenced from the JSON in the data part.  Furthermore, attachments that are referenced multiple times from the JSON in the data part may be added with multiple copies into the database.

## Data part format

The data part is an `application/json` part that always appears immediately after each command part and defines the data for the operation.  Although the data part is always JSON, the specific format of the data part varies depending on the specific operation.  Data that is not convenient to embed within the JSON can be split out into attachments, and the JSON can then reference the appropriate attachment name that was defined in the command part index of attachments.

### Set Variables data

The `SET VARIABLES` data is a JSON object that maps names of variables within the `vars` table to their values.  The variable names must follow the name format defined in `Database.md`.  The variable values are always strings.  However, you may instead specify an empty array as a variable value to indicate that the variable should be deleted from the `vars` table if it is present.  Variables that are not defined yet will get defined, while variables that have already been defined will have their value updated or be deleted, depending on whether a string value or an empty array was specified in the JSON.  Variables already in the `vars` table that are not referenced within the JSON object are left as-is.

There is no way to reference attachments from Set Variables data.  Any attachments for the operation will be ignored.

### Create Page data

The `CREATE PAGE` data is a JSON object that completely specifies a page and all associated resources and embeds.  If no page with the given name exists yet, a new page will be added to the Dog CMS database with the data specified in this operation.  If a page with the given name already exists, it will be completely deleted and then it will be replaced entirely with the new page data specified in this operation.

The following simple properties must be present on the top-level JSON object:

- `name` : (string) the unique name/ID of the page
- `time` : (string) the timestamp of the page, in yyyy-mm-ddThh:mm:ssZ format in GMT
- `url` : (string) the canonical URL for the page

`name` must follow the name format defined in `Database.md`.  `time` must be in the year 1970 or later in GMT.  `url` is either the full canonical URL path, or a URL suffix if `page_prefix` is defined in the `vars` table.

The following simple properties are optional on the top-level JSON object:

- `pin` : (integer) the pin class of the page

If not present, `pin` is assumed to be zero meaning a regular page.  A value of -1 means the page is unlisted and not in the catalog.  A value greater than zero means the page is pinned to the start of the catalog, with higher pin classes being earlier in the sequence.

The following properties are required but have a special "reference" semantics:

- `meta` : the JSON metadata for the page
- `list` : the catalog listing rendering for the page
- `page` : the page rendering for the page

Each of these property values is either a string or an array containing a single string.  If it is a string, then the string contains the value of the property.  If it is an array containing a single string, that string names an attachment that was defined in the attachment index in the command part of the operation.  The data from the attachment is then used as the value of the property.

Note that if the `meta` property is specified directly as a string value, it JSON embedded within a string value.

The following properties are optional but have a special compound format:

- `resources` : resources attached to the page
- `embeds` : embeds attached to the page

Both properties are assumed to be empty maps if they are not present.  If present, they are a JSON object that is treated as a dictionary mapping string keys (property names) to values.

The `resources` property value is a map of resource names to resource values.  The resource name must follow the name format defined in `Database.md`.  The value is an array of two values.  The first value is a string that names a type in the MIME table to use for the resource.  The second value is a string that names an attachment in the attachment index from the command part of the operation.

The `embed` property value is a map of embed names to embed values.  The embed name must follow the name format defined in `Database.md`.  The value is an array of two values.  The first value is an integer in range [0, 3] that selects the processing to perform on the embed -- see the `eproc` field documentation in the `embed` table in `Database.md` for further information.  The second value is a string that names an attachment in the attachment index from the command part of the operation.

...
