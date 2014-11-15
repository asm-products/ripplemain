(function (window, chrome, $, undefined) {
var internals = {};


var friends = [
  {id: 1, text: "David Brooks"},
  {id: 2, text: "Laura Daniels"},
  {id: 3, text: "Seb Merrick"},
  {id: 4, text: "Fiona Ward"}
];

/**
 * Retrieve Chromes active tab
 *
 * @param  {Function} next
 * @return {Object}
 */
internals.getActiveTabUrl = function(next) {
  if (!chrome.tabs) {
    return next();
  }

  chrome.tabs.query({
    active: true,
    windowId: chrome.windows.WINDOW_ID_CURRENT
  }, function (tabs) {
    return next(tabs[0]);
  });
};

document.addEventListener('DOMContentLoaded', function () {
  if (chrome) {
    internals.getActiveTabUrl(function(tab) {
      if (!tab) {
        return;
      }
      var $url = $('.js-url');
      var $title = $('.js-title');
      var $image = $('.js-image');
      $url.html(tab.url);
      $title.html(tab.title);
      if (tab.favIconUrl) {
        $image.src(tab.favIconUrl);
      }
    });
  }

  $('.js-friends').select2({
    multiple: true,
    data: friends,
    createSearchChoice: function (name) {
      return { id: name, text: name };
    },
    ajax: { // instead of writing the function to execute the request we use Select2's convenient helper
        url: "/assets/friends.json",
        dataType: 'json',
        quietMillis: 250,
        // data: function (term, page) {
        //   return {
        //     q: term, // search term
        //   };
        // },
        results: function (data, page) { // parse the results into the format expected by Select2.
            // since we are using custom formatting functions we do not need to alter the remote JSON data
            return { results: data.items };
        },
        cache: true
    },
  });
});

})(window, window.chrome, window.jQuery);