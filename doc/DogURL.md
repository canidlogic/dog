# Dog URL handling

The last step in dynamic page generation is to resolve `dog://` URLs.  This step is performed after the `HTML::Template` generation has completed, so `dog://` URLs generated during that phase will also be processed.

Specifically, the following character sequence is searched for:

    [[dog://

Anywhere this sequence of eight _case sensitive_ characters occurs is processed by the Dog CMS URL resolver.  If you need to include this sequence of eight characters without it being processed, you can escape it as follows:

    [[dog://!

This causes the Dog CMS URL resolver to replace this sequence of nine characters with the first eight characters in the output (without the trailing `!` exclamation mark).

In all other cases, the `dog://` URL must be enclosed in double square brackets:

    [[dog://...]]

Within the enclosed `...`, neither the sequence `[[` nor the sequence `]]` may occur.

The following subsections document what kind of special URLs are allowed in this `dog://` scheme.

## Dog config URLs

Dog URLs can be replaced by the value of any configuration value in the `vars` table of the Dog CMS database by using the following syntax:

    [[dog://config/{varname}]]

In this case, the record from the `vars` table that has a key `{varname}` is retrieved and the whole dog URL reference is replaced by the value field in that record.  If the value field is NULL, the dog URL reference is replaced with an empty string.  An error occurs if no configuration variable with name `{varname}` is found.

## Dog resource URLs

Dog URLs can be replaced by the URL to a specific global or local resource by using one of the following syntaxes:

    [[dog://site/{resname}]]
    [[dog://page/{pageid}/{resname}]]
    [[dog://here/{resname}]]

The first syntax is used for global resources.  To use this syntax, a variable named `global_res_dir` must be defined in the `vars` table in the Dog CMS database.  `{resname}` is appended to this variable value to form a URL to a global resource, and this resulting URL replaces the dog URL reference.  For example:

    global_res_dir = "http://www.example.com/cgi-bin/resource.cgi?name="
    
    Dog URL example:
    <img src="[[dog://site/my_logo]]"/>

    Resolution:
    <img src="http://www.example.com/cgi-bin/resource.cgi?name=my_logo"/>

The second syntax is used to select a resource that is attached to a specific page.  First, the record for the page with ID `{pageid}` is looked up in the page table in the Dog CMS database.  The page base field is taken from this record.  If a variable named `local_res_prefix` is defined in the `vars` table, then its value is prefixed to the page base field to form the local base; otherwise, the local base is the same as the page base.  Finally, `{resname}` is appended to the local base to form a URL to a resource local to a specific page, and this resulting URL replaces the dog URL reference.  For example:

    local_res_prefix = "/cgi-bin/page.cgi?name="

    Page "my_page":
    page_base = "my_page&resource="

    Dog URL example:
    <img src="[[dog://page/my_page/my_photo]]"/>

    Resolution:
    <img src="/cgi-bin/page.cgi?name=my_page&resource=my_photo"/>

The third syntax may only be used when generating a specific page, and may __not__ be used when generating the catalog.  The `here` part of the URL is replaced with `page/{pageid}` where `{pageid}` is the ID of the page that is currently being generated, and then the dog URL is processed the same way as for the second syntax explained above.  This allows pages to refer to their resources without knowing their own page ID.

## Dog page URLs

Dog URLs can be replaced by the URL to a specific page by using one of the following syntaxes:

    [[dog://page/{pageid}]]
    [[dog://here]]

The first syntax is used to get the URL to a page with ID `{pageid}`.  It works by looking up the page record with that ID in the page table in the Dog CMS database.  The page URL field is taken from this record.  Then, if a variable named `local_page_prefix` is defined in the `vars` table, its value is prefixed to the page URL value to form the replacement URL; otherwise, the replacement URL is the same as the page URL field value.  For example:

    local_page_prefix = "/~username/view/"

    Page "my_page":
    page_url = "my_page/"

    Dog URL example:
    <a href="[[dog://page/my_page]]"/>

    Resolution:
    <a href="/~username/view/my_page/"/>

The second syntax may only be used when generating a specific page, and may __not__ be used when generating the catalog.  The `here` part of the URL is replaced with `page/{pageid}` where `{pageid}` is the ID of the page that is currently being generated, and then the dog URL is processed the same way as for the first syntax explained above.  This allows pages to refer to themselves without knowing their own page ID.
