/**
 * Action.js
 * Save to Link Saver - Share Extension
 *
 * This JavaScript file is used by Safari to extract page information
 * when the user shares a web page to the Link Saver extension.
 */

var Action = function() {};

Action.prototype = {
    /**
     * Called when the extension is invoked.
     * Extracts URL, title, and selected text from the current page.
     */
    run: function(arguments) {
        arguments.completionFunction({
            "url": document.URL,
            "title": document.title,
            "selectedText": window.getSelection().toString()
        });
    },

    /**
     * Called after the extension completes.
     * Can be used to execute any cleanup or custom JavaScript.
     */
    finalize: function(arguments) {
        // Optional: Execute custom JavaScript after extension completes
        // var customJavaScript = arguments["customJavaScript"];
        // if (customJavaScript) {
        //     eval(customJavaScript);
        // }
    }
};

var ExtensionPreprocessingJS = new Action;
