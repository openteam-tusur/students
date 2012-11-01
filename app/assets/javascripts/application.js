// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// the compiled file.
//
// WARNING: THE FIRST BLANK LINE MARKS THE END OF WHAT'S TO BE PROCESSED, ANY BLANK LINE SHOULD
// GO AFTER THE REQUIRES BELOW.
//
//= require jquery
//= require_tree .

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
      sortList: [[2,0]],
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
