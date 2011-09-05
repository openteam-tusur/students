$(function() {
  $(".focus_first").focus();
  $(".tablesorter").tablesorter();
  $(".tablesorter tbody tr").mouseover(function() {
    $("td", this).css({
      "color": "#000",
      "background-color": "#fbf6c9"
    });
  });
  $(".tablesorter tbody tr").mouseout(function() {
    $("td", this).css({
      "color": "#3d3d3d",
      "background-color": "#fff"
    });
  });
});
