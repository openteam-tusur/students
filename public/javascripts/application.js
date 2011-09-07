$(function() {

  if ($.fn.tablesorter) {
    $.tablesorter.addWidget({
      id: "indexFirstColumn",
      format: function(table) {
        for(var i=0; i <= table.tBodies[0].rows.length; i++) {
          $("tbody tr:eq(" + (i - 1) + ") td:first",table).html(i);
        };
      }
    });

    $.tablesorter.addParser({
      id: "birthday",
      is: function(s) {
        return false;
      },
      format: function(s) {
        return s.split(".")[2] + s.split(".")[1] + s.split(".")[0];
      },
      type: 'numeric'
    });


    $(".tablesorter").tablesorter({
      widgets: ['indexFirstColumn'],
      headers: {
        0: {
          sorter: false
        },
        3: {
          sorter: "birthday"
        }
      }
    });
  };

  $(".focus_first").focus();

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

