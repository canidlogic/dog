# Dog URL handling

The Dog CMS engine supports a special URL syntax for dynamically generating URLs and embedding and generating textual content.  Dog URL processing is at heart a simple search-and-replace function.  Specifically, the following character sequence is searched for:

    [[dog://

Anywhere this sequence of eight _case sensitive_ characters occurs is processed by the Dog CMS URL resolver.  If you need to include this sequence of eight characters without it being processed, you can escape it as follows:

    [[dog://!

This causes the Dog CMS URL resolver to replace this sequence of nine characters with the first eight characters in the output (without the trailing `!` exclamation mark).

In all other cases, the `dog://` URL must be enclosed in double square brackets:

    [[dog://...]]

Within the enclosed `...`, neither the sequence `[[` nor the sequence `]]` may occur.

Since the search-and-replace functionality is low-level and has nothing to do with XML or HTML document structure, Dog URLs can be included and processed anywhere, even in places like JavaScript blocks, embedded CSS stylesheets, HTML comments, and XML processing instructions.  This also means that you have to be careful to escape literal `[[dog://` characters sequences _everywhere_ in the document.

The following subsections document what kind of special URLs are allowed in this `dog://` scheme.

## Dog resource URLs

Dog URLs can be replaced by the URL to a specific global or local resource by using one of the following syntaxes:

    [[dog://site/{resname}]]
    [[dog://page/{pageid}/{resname}]]
    [[dog://here/{resname}]]

The first syntax is used for global resources.  To use this syntax, a variable named `global_res_dir` must be defined in the `vars` table in the Dog CMS database.  `{resname}` is appended to this variable value to form a URL to a global resource, and this resulting URL replaces the Dog URL reference.  For example:

    global_res_dir = "http://www.example.com/cgi-bin/resource.cgi?name="
    
    Dog URL example:
    <img src="[[dog://site/my_logo]]"/>

    Resolution:
    <img src="http://www.example.com/cgi-bin/resource.cgi?name=my_logo"/>

The second syntax is used to select a resource that is attached to a specific page.  First, the record for the page with ID `{pageid}` is looked up in the page table in the Dog CMS database.  The page base field is taken from this record.  If a variable named `local_res_prefix` is defined in the `vars` table, then its value is prefixed to the page base field to form the local base; otherwise, the local base is the same as the page base.  Finally, `{resname}` is appended to the local base to form a URL to a resource local to a specific page, and this resulting URL replaces the Dog URL reference.  For example:

    local_res_prefix = "/cgi-bin/page.cgi?name="

    Page "my_page":
    page_base = "my_page&resource="

    Dog URL example:
    <img src="[[dog://page/my_page/my_photo]]"/>

    Resolution:
    <img src="/cgi-bin/page.cgi?name=my_page&resource=my_photo"/>

The third syntax is a context-sensitive way of referring to resources that are attached to a specific page without having to explicitly include the page ID of the current page.  Whenever Dog URLs are processed, there is a "current page" setting that either contains the page ID of the current page in the context, or is empty meaning that no current page is in the context.  When generating a specific page, the "current page" is always the page ID of the specific page that is being generated.  When generating a listing for a specific page within a catalog page, the "current page" is always the page ID of the specific page whose entry is being generated.  When generating a full catalog page without reference to any specific page, the "current page" is empty.

The third syntax may only be used when the "current page" is not empty.  The `here` part of the Dog URL is replaced with `page/{pageid}` where `{pageid}` is the page ID value stored in the "current page" context setting.  Then, the replaced Dog URL is processed the same way as for the second syntax explained above.

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

The second syntax makes use of the concept of a "current page" setting in the context (see the previous section for details).  The second syntax may only be used when the "current page" setting in the context is not empty.  The `here` part of the URL is replaced with `page/{pageid}` where `{pageid}` is the ID of the page that is the "current page" in the context.  The Dog URL is then processed the same way as for the first syntax explained above.  This is especially useful for generating a link to the page URL from a catalog page listing entry, since the "current page" for the page listing will be set to the correct page.

## Dog text embedding

Dog URLs can also be replaced by literal text from the `embed` table by using one of the following syntaxes:

    [[dog://embed/site/{embedname}]]
    [[dog://embed/page/{pageid}/{embedname}]]
    [[dog://embed/here/{embedname}]]

The first syntax is used for global embeds.  These refer to records in the `embed` table that are not associated with any specific page.  The `{embedname}` is the name of the specific embed record, which must be unique within the set of all global embeds.

The second syntax is used for embeds specific to the page with ID `{pageid}`.  The `{embedname}` for this syntax must only be unique within the set of all embeds for that specific page.

The third syntax makes use of the concept of a "current page" setting in the context (see the previous sections for details).  This syntax may only be used when the "current page" setting in the context is not empty.  The `here` part of the URL is replaced with `page/{pageid}` where `{pageid}` is the ID of the page that is the "current page" in the context.

The previous kinds of Dog URLs were replaced with a URL reference that is included in the final text.  However, this syntax instead generates text and replaces the Dog URL with the generated text, thereby embedding the content directly in the page instead of linking to it.

Records within the `embed` table can choose what kind of processing is applied to the text before it is embedded.  There can be no processing (in which case the text is just echoed in place of the Dog URL), or recursive Dog URL processing, or template processing, or both template and recursive Dog URL processing.  When both template and recursive Dog URL processing are selected at the same time, template processing is always done first, and then recursive Dog URL processing.

Dog URL processing is actually always done.  When a text record in the `embed` table specifies that there should be no Dog URL processing, then what actually happens is that any character sequences `[[dog://` found in the text are escaped as `[[dog://!` so that the result of applying Dog URL processing will be exactly the same as if there was no Dog URL processing.

Recursive Dog URL processing means that before the original Dog URL is replaced, Dog URLs in the generated output are themselves processed and replaced.  This can allow for multi-level recursive text processing.  To prevent infinite loops, the Dog CMS text engine keeps track of a stack of embed records and makes sure when a new embed is recursively processed, that it does not already exist on the embed record stack.  This prevents infinite loops within the recursion.

To prevent excessive processing, the maximum depth of recursive Dog URL resolution is also limited.  By default, this limit is 32 levels of recursion.  However, if the configuration variable `dog_recurse_limit` is defined in the `vars` table, then the integer value there (which must be greater than zero) is used instead as the limit.

Template processing works according to the `HTML::Template` Perl module.  See `PageTemplate.md` for further details about templates.
