(function (window, chrome, $, undefined) {
var internals = {};


var friends = [
  "David Brooks", "Laura Daniels", "Seb Merrick", "Fiona Ward"
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

/**
 * Get the friends matching the query
 * provided by the typeahead plugin.
 *
 * SHOULD BE SWAPPED OUT FOR AN API CALL
 * TO THE RIPPLE SERVICE TO USER'S GET FRIENDS
 *
 * @param  {String}   query
 * @param  {Function} next
 * @return {Array}
 */
internals.getFriends = function (query, next) {
  var matches = [];
  var substrRegex = new RegExp(query, 'i');

  $.each(friends, function(i, str) {
    if (substrRegex.test(str)) {
      // the typeahead jQuery plugin expects suggestions
      // to be an object
      matches.push({ value: str });
    }
  });

  return next(matches);
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

  $('.js-friends').typeahead({
    hint: true,
    highlight: true,
    minLength: 1,
  }, {
    name: 'friends',
    source: internals.getFriends
  });
});

})(window, window.chrome, window.jQuery);