(function (window, chrome, $, undefined) {
var internals = {};

var emailRegex = /^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/;

var friends = [
  {"id": 1, "text": "David Brooks"},
  {"id": 2, "text": "Laura Daniels"},
  {"id": 3, "text": "Seb Merrick"},
  {"id": 4, "text": "Fiona Ward"}
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
    createSearchChoice: function (email, data) {
      var matches = $(data).filter(function () {
        return this.text.toLowerCase() === email.toLowerCase();
      });
      // if the text isn't a valid email or the email
      // already exists, don't show results
      if (!emailRegex.test(email) || matches.length) {
        return null;
      }

      return { id: email, text: email };
    }
  });
});

})(window, window.chrome, window.jQuery);