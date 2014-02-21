document.open_sse = function(url) {
  if (!!window.EventSource) {
    var source = new EventSource(url);

    source.onmessage = function(e) {
      console.log(e.data);
    };
    
    source.onopen = function(e) {
      console.log('connection opened');
    };
    
    source.onerror = function(e) {
      source.close();
    };
  }
};
