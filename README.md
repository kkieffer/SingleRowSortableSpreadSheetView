# SingleRowSortableSpreadSheetView.swift

This file extends the functionality of: [kishikawakatsumi/SpreadsheetView](http:www.github.com/kishikawakatsumi/SpreadsheetView)

It provides a view where the user selects one and only one entire row at once,
and includes a sorting capability delegation when the user selects a column header.


## To implement

Include this file with your ViewController that has an outlet to the SpreadsheetView. The
example ViewController, ported from the "Class Data" example from the SpreadsheetView framework,
shows how to implement.

The existing UITouch is not used from the framework, but instead a gesture handler is
installed to handle taps and long presses.

The view controller must implement SpreadsheetActionsDelegate and call addTapAndLongPressGestures()
to enable the functionality.

To maintain the selected row after sorting, the delegate must maintain a unique object for each row,
and be able to provide it and test it for equality.  The example uses unique Strings in the first column.

## License

This file available under the MIT license. See the LICENSE file for more info.
