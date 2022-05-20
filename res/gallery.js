"use strict";

/*
 * gallery.js
 * ==========
 * 
 * JavaScript code that dynamically generates the photo gallery content.
 */

// Wrap everything in an anonymous function that we immediately invoke
// after it is declared -- this prevents anything from being implicitly
// added to global scope
(function() {

  /*
   * Configuration constants
   * =======================
   * 
   * These are loaded from JSON data blocks embedded in the body of the
   * HTML document at the beginning of handleLoad().
   */
  
  // The UID of the gallery being displayed, as an integer
  //
  var GALLERY_UID = false;
  
  // The URI path to photo attachments, excluding the post UID and
  // attachment index that will be directly suffixed to this, as a
  // string
  //
  var PHOTO_PATH = false;
  
  // The string used when there are no photos in the gallery
  //
  var EMPTY_TEXT = false;
  
  // The display name of the photo gallery as an (unescaped) string
  //
  var GALLERY_NAME = false;
  
  // The description of the photo gallery as an (unescaped) string
  //
  var GALLERY_DESC = false;
  
  // An array of integers storing the attachment indices of each photo,
  // in ascending order of photo number; where photos have multiple
  // resolution classes, the attachment index of the largest resolution
  // class is stored in this array
  //
  var PHOTO_LIST = false;

  /*
   * Local functions
   * ===============
   */
  
  /*
   * Report an error to console and throw an exception for a fault
   * occurring within this module.
   *
   * Parameters:
   *
   *   func_name : string - the name of the function in this module
   *
   *   loc : number(int) - the location within the function
   */
  function fault(func_name, loc) {
    
    // If parameters not valid, set to unknown:0
    if ((typeof func_name !== "string") || (typeof loc !== "number")) {
      func_name = "unknown";
      loc = 0;
    }
    loc = Math.floor(loc);
    if (!isFinite(loc)) {
      loc = 0;
    }
    
    // Report error to console
    console.log("Fault at " + func_name + ":" + String(loc) +
                  " in galmain");
    
    // Throw exception
    throw ("galmain:" + func_name + ":" + String(loc));
  }

  /*
   * Given a string containing anything, escape the ampersand and angle
   * bracket characters so it can be safely used as plain-text in HTML.
   * 
   * Parameters:
   * 
   *   str - the string to escape
   * 
   * Return:
   * 
   *   the escaped string
   */
  function html_esc(str) {
    
    var func_name = "html_esc";
    
    // Check parameter
    if (typeof(str) !== "string") {
      fault(func_name, 10);
    }
    
    // First replace ampersands
    str = str.replace("&", "&amp;");
    
    // Second replace angle brackets
    str = str.replace("<", "&lt;");
    str = str.replace(">", "&gt;");
    
    // Return escaped string
    return str;
  }

  /*
   * Generate HTML content to go in the display DIV where there is at
   * least one photo in the gallery.
   * 
   * Return:
   * 
   *   the generated HTML code
   */
  function gen_html() {
    var func_name = "gen_html";
    var code, i, uidstr, full, thumb;
    
    // Check state
    if (PHOTO_LIST.length < 1) {
      fault(func_name, 10);
    }
    
    // Start the code out empty
    code = "";
    
    // Add each photo
    for(i = 0; i < PHOTO_LIST.length; i++) {
      // Get the full-resolution index
      full = PHOTO_LIST[i];
      
      // Determine the thumbnail index
      if ((full >= 7000) && (full <= 8999)) {
        thumb = full - 6000;
      
      } else if ((full >= 5000) && (full <= 6999)) {
        thumb = full - 4000;
        
      } else if ((full >= 3000) && (full <= 4999)) {
        thumb = full - 2000;
        
      } else if ((full >= 1000) && (full <= 2999)) {
        thumb = full;
        
      } else {
        fault(func_name, 20);
      }
      
      // Each photo is in a photobox DIV
      code = code + "<div class=\"photobox\">";
      
      // The actual image is in its own photoframe DIV
      code = code + "<div class=\"photoframe\">";
      
      // Each photo is a link to the full-resolution photo
      code = code + "<a href=\"" + PHOTO_PATH + GALLERY_UID.toString();
      code = code + full.toString() + "\">";
      
      // Write the image element, using the thumbnail
      code = code + "<img src=\"" + PHOTO_PATH + GALLERY_UID.toString();
      code = code + thumb.toString() + "\"/>";
      
      // Finish the photo frame code
      code = code + "</a></div>";
      
      // Now we add the caption frame that holds the gallery UID and the
      // attachment index of the largest resolution class for this
      // photo, so that the photo is uniquely identified across all
      // galleries
      code = code + "<div class=\"capframe\">";
      code = code + GALLERY_UID.toString() + "-" + full.toString();
      code = code + "</div>";
      
      // Finish the whole photobox
      code = code + "</div>";
    }
    
    // Return the generated code
    return code;
  }

  /*
   * Public functions
   * ================
   */

  /*
   * Function invoked when the page is finally loaded.
   */
  function handleLoad() {
    
    var func_name = "handleLoad";
    var i, x, e, dbid, js;
    
    // Load configuration constants
    try {
      // Handle both data blocks the same way
      for(i = 0; i < 2; i++) {
        // Determine data block ID
        if (i === 0) {
          dbid = "gconfigjson";
        } else if (i === 1) {
          dbid = "galleryjson";
        } else {
          fault(func_name, 100);
        }
        
        // Get the data block element and parse the JSON
        e = document.getElementById(dbid);
        if (e) {
          js = JSON.parse(e.text);
        } else {
          fault(func_name, 110);
        }
        
        // Handle the specific JSON
        if (dbid === "gconfigjson") { //////////////////////////////////
          // Check that we got an object
          if (typeof js !== "object") {
            fault(func_name, 1000);
          }
          
          // Check for required parameters
          if ((!("galleryuid" in js)) || (!("photopath" in js)) ||
              (!("emptytext" in js))) {
            fault(func_name, 1100);
          }
          
          // Check required parameter types
          if ((typeof js.galleryuid !== "number") ||
              (typeof js.photopath  !== "string") ||
              (typeof js.emptytext  !== "string")) {
            fault(func_name, 1200);
          }
          if (Math.floor(js.galleryuid) !== js.galleryuid) {
            fault(func_name, 1300);
          }
          if (!((js.galleryuid >= 100000) &&
                  (js.galleryuid <= 999999))) {
            fault(func_name, 1400);
          }
          
          // Store the parsed information
          GALLERY_UID = js.galleryuid;
          PHOTO_PATH  = js.photopath;
          EMPTY_TEXT  = js.emptytext;
          
        } else if (dbid === "galleryjson") { ///////////////////////////
          // Check that we got an object
          if (typeof js !== "object") {
            fault(func_name, 2000);
          }
          
          // Check for required parameters
          if ((!("gname" in js)) || (!("gdesc" in js)) ||
                (!("photos" in js))) {
            fault(func_name, 2100);
          }
          
          // Check required parameter types
          if ((typeof js.gname  !== "string") ||
              (typeof js.gdesc  !== "string") ||
              (typeof js.photos !== "object") ||
              (!(js.photos instanceof Array))) {
            fault(func_name, 2200);
          }
          for(x = 0; x < js.photos.length; x++) {
            if (typeof js.photos[x] !== "number") {
              fault(func_name, 2300);
            }
            if (Math.floor(js.photos[x]) !== js.photos[x]) {
              fault(func_name, 2400);
            }
            if (!((js.photos[x] >= 1000) && (js.photos[x] <= 8999))) {
              fault(func_name, 2500);
            }
          }
          
          // Store the parsed information
          GALLERY_NAME = js.gname;
          GALLERY_DESC = js.gdesc;
          PHOTO_LIST   = js.photos;
          
        } else { ///////////////////////////////////////////////////////
          fault(func_name, 120);
        }
      }
      
    } catch {
      fault(func_name, 10);
    }
    
    // Get the DIV where we will place the generated content
    e = document.getElementById("galdiv");
    if (!e) {
      fault(func_name, 20);
    }
    
    // Fill the DIV with content
    if (PHOTO_LIST.length > 0) {
      // There are photos, so generate the HTML
      e.innerHTML = gen_html();
      
    } else {
      // There are no photos, so just put the empty text
      e.innerHTML = html_esc(EMPTY_TEXT);
    }
  }

  /*
   * Export declarations
   * ===================
   * 
   * All exports are declared within a global "galmain" object.
   */
  window.galmain = {
    "handleLoad": handleLoad
  };

}());

/* * * * * * * * * * * *
 *                     *
 * Program entrypoint  *
 *                     *
 * * * * * * * * * * * */

// Check if document DOM is loaded, calling handleLoad directly if it is
// already loaded and otherwise registering an event handler
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', galmain.handleLoad);
} else {
  galmain.handleLoad();
}
