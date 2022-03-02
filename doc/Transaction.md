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

Note that if the `meta` property is specified directly as a string value, it will be JSON embedded within a string value.

The following properties are optional but have a special compound format:

- `resources` : resources attached to the page
- `embeds` : embeds attached to the page

Both properties are assumed to be empty maps if they are not present.  If present, they are a JSON object that is treated as a dictionary mapping string keys (property names) to values.

The `resources` property value is a map of resource names to resource values.  The resource name must follow the name format defined in `Database.md`.  The value is an array of two values.  The first value is a string that names a type in the MIME table to use for the resource.  The second value is a string that names an attachment in the attachment index from the command part of the operation.

The `embeds` property value is a map of embed names to embed values.  The embed name must follow the name format defined in `Database.md`.  The value is an array of two values.  The first value is an integer in range [0, 3] that selects the processing to perform on the embed -- see the `eproc` field documentation in the `embed` table in `Database.md` for further information.  The second value is a string that names an attachment in the attachment index from the command part of the operation.

### Edit Page data

The `EDIT PAGE` data is a JSON object that identifies a page and then specifies updates to the page data.  Any page data can be updated with this command, except for the page name, which must instead be altered by a `RENAME` command.

The format of the data of this command is the same as the format of the data for the `CREATE PAGE` command, with the following exceptions:

(1) __All properties are optional, except the `name` property that identifies which page is being edited.__  Properties that are not present will not be edited and left as-is.  Properties that are present will overwrite their current values, except for the "compound" properties `resources` and `embeds` described below.

(2) __If present, the `resources` property edits attached resources.__  Resources referenced from the provided `resources` map are added as newly attached resources.  If resources already exist with names specified in the map, the new resource data overwrites the existing resource data.  In order to delete existing attached resources without replacing them, you can specify a value for the resource that is an empty array (this syntax is not allowed by the `CREATE PAGE` command).  If no `resources` property is present within the `EDIT PAGE` data, all attached resources are left as-is.

(3) __If present, the `embeds` property edits attached embeds.__  Embeds referenced from the provided `embeds` map are added as newly attached embeds.  If embeds already exist with names specified in the map, the new embed data overwrites the existing embed data.  In order to delete existing attached embeds without replacing them, you can specify a value for the embed that is an empty array (this syntax is not allowed by the `CREATE PAGE` command).  If no `embeds` property is present within the `EDIT PAGE` data, all attached embeds are left as-is.

### Drop Page data

The `DROP PAGE` data is a JSON array of strings.  Each string is the name of a page that should be dropped.  If there are names in the array that do not correspond to any existing page, they are ignored.  All of the named pages are dropped from the database, along with all their attached resources and embeds.

There is no way to reference attachments from Drop Page data.  Any attachments for the operation will be ignored.

### Set Types data

The `SET TYPES` data is a JSON object.  The property names of this JSON object are the keys for data types to add into the `mime` table, and the property keys of this JSON object are strings specifying the MIME type for this data type.  You may also specify an empty array for a MIME type to delete a data type key if it currently exists in the `mime` table.  Otherwise, the new data type is added to the `mime` table, or the existing data type is updated with the new MIME type value.

There is no way to reference attachments from Set Types data.  Any attachments for the operation will be ignored.

### Set Global Resources data

The `SET GLOBAL RESOURCES` data has the same format as the `resources` property within the `CREATE PAGE` data, except it also allows empty arrays to be specified as values to indicate that the named resource should be deleted if it exists.  In other words, the data is a JSON object where property names correspond to global resource names and property values are arrays of two values, the first being a data type name in the `mime` table and the second naming an attachment for this operation that contains the resource data -- or, use an empty array to indicate that a global resource should be deleted.

### Set Global Embeds data

The `SET GLOBAL EMBEDS` data has the same format as the `embeds` property within the `CREATE PAGE` data, except it also allows empty arrays to be specified as values to indicate that the named embed should be deleted if it exists.  In other words, the data is a JSON object where property names correspond to global embed names and property values are arrays of two values, the first being an `eproc` integer code in range [0, 3] and the second naming an attachment for this oepration that contains the embed data -- or use an empty array to indicate that a global embed should be deleted.

### Rename data

The `RENAME` data requires a _context,_ a _type,_ and a _map._  The context indicates where things are being renamed, the type indicates what kind of thing is being renamed, and the map indicates the actual renaming.

Specifically, the `RENAME` data is a JSON object that has three properties:  `rncontext`, `rntype`, and `rnmap`.  If you are renaming resources or embeds that are attached to a specific page, then `rncontext` will be a string that names the page within which attachments are to be renamed.  In all other cases, `rncontext` must be an empty array indicating that the renaming context is global.

The `rntype` property must either be the string value `page` or `resource` or `embed` indicating what kind of thing is being renamed.  If `page` is specified, then `rncontext` must be an empty array, because there is no way of attaching pages to pages.  If `resource` or `embed` is specified, then an empty array value for `rncontext` means that global resources or global embeds are being renamed, while a page name means that resources or embeds attached to a specific page are being renamed.

Finally, the `rnmap` is a JSON object that specifies the actual renaming transforms.  The property names of this object are the old names and the property values of this object must be strings giving the new names.  All of the old names must currently exist in the database or the renaming operation will fail.  Existing objects that are not referenced from the `rnmap` table are not affected by the renaming.

The way renaming works is that first all of the selected objects are given temporary, random names that are not used.  Then, each of the temporarily renamed objects is changed to their new names one by one.  The operation fails if any of the temporarily renamed objects map to names that already exist within the database.  This means you _can't_ use renaming to overwrite one object with another, nor can you rename two objects to the same new name.  However, you _can_ use renaming to swap the names of two existing objects, since the two-pass renaming operation described above will allow for that.

Since each renaming operation is limited to a specific context and a specific type of object, multiple renaming operations may be required in a sequence if you are renaming a lot of different things.
