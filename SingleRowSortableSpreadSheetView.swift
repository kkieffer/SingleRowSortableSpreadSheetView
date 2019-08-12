//
//  SingleRowSortableSpreadSheetView.swift
//
//  Created by Kevin Kieffer on 8/8/19.
//
//  Extends the functionality of the SpreadsheetView framework available at:
//  https://github.com/kishikawakatsumi/SpreadsheetView
//
//  Provides a view where the user selects one and only one entire row at once,
//  and includes a sorting capability delegation when the user selects a column header.
//
//  The existing UITouch is not used from the framework, but instead a gesture handler is
//  installed to handle taps and long presses.
//
//  The view controller must implement SpreadsheetActionsDelegate and call addTapAndLongPressGestures()
//  to enable the functionality.
//
//  To maintain the selected row after sorting, the delegate must maintain a unique object for each row,
//  and be able to provide it and test it for equality
//

import UIKit
import SpreadsheetView


protocol SpreadsheetActionsDelegate : SpreadsheetViewDelegate {
    
    
    func sortBy(column: Int)            //delegate receives notification to sort by the provided column index
    func didSelectRow(at row: Int)      //delegate receives notification that a row other than the header was selected, row > 0
    func longPressDidEnd(at row: Int)   //delegate receives notification that a row other than the header was long pressed, row > 0
    
    //Delegate should return a unique object associated with the row
    func uniqueObject(forRow row : Int) -> Any
    
    //Delete should determine if the two unique objects are equal
    func uniqueObjectsAreEqual(_ obj1 : Any, _ obj2 : Any) -> Bool
}


extension SpreadsheetView : SpreadsheetViewDelegate {
    
    //The delegate must be a SpreadsheetActionsDelegate or the callbacks will not work
    private func getDelegate() -> SpreadsheetActionsDelegate? {
        
        if let actionsDelegate = delegate as? SpreadsheetActionsDelegate {
            return actionsDelegate
        }
        else {
            return nil
        }
        
    }
    
    
    func addTapAndLongPressGestures(withMinLongPressDuration : Double) {
        
        //These must be set to true or selection is impossible
        allowsSelection = true
        allowsMultipleSelection = true
        
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
        longPressRecognizer.delaysTouchesBegan = false
        longPressRecognizer.minimumPressDuration = withMinLongPressDuration
        addGestureRecognizer(longPressRecognizer)
        
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tapRecognizer)
        
    }
    
    //On tap, notify the delegate to sort if tap was on the header, otherwise select the row and let the delegate know
    @objc func handleTap(sender: UILongPressGestureRecognizer) {
        
        guard let delegate = getDelegate() else {
            return
        }
        
        if let indexPath = indexPathForItem(at: sender.location(in: self)) {
            
            if indexPath.row == 0 {  //header - sort
                
                var unique : Any?
                
                if let selectedRow = getSelectedRow() {  //has a selected row
                    unique = delegate.uniqueObject(forRow: selectedRow)  //get a unique object at the selected row
                }
                
                delegate.sortBy(column: indexPath.column)  //tell the delegate to sort its model
                reloadData()  //reload the data from the model
                
                if unique != nil {  //if there was a previously selected row
                    selectRow(forUniqueObject: unique!)  //now reselect the row with the unique object
                }
            }
                
            else {  //on a row, select it
                selectRow(at: indexPath.row)
                delegate.didSelectRow(at: indexPath.row)
            }
        }
        
    }
    

    
    //If not the header row, on long press start, deselect existing rows, highlight the new row.
    //When finished, notify the delegate of the long press
    @objc func handleLongPress(sender: UILongPressGestureRecognizer) {
        
        guard let delegate = getDelegate() else {
            return
        }
        
        if let indexPath = indexPathForItem(at: sender.location(in: self)) {
            if indexPath.row == 0 {  //no longpress on column headers
                return
            }
            switch sender.state {
            case .began:
                deselectAll()
                fallthrough
            case .changed:
                highlight(on: true, atRow: indexPath.row)
            case .ended:
                selectRow(at: indexPath.row)
                delegate.didSelectRow(at: indexPath.row)
                delegate.longPressDidEnd(at: indexPath.row)
            default:
                break
            }
        }
        
    }
    

    
    //Highlight the row, on or off
    func highlight(on : Bool, atRow row : Int) {
        for col in 0..<numberOfColumns {
            let ipath = IndexPath(row: row, column: col)
            cellForItem(at: ipath)?.isHighlighted = on
        }
    }
    
    //Select all columns in the row
    func selectRow(at row : Int) {
        
        deselectAll()
        for col in 0..<numberOfColumns {
            let ipath = IndexPath(row: row, column: col)
            selectItem(at: ipath, animated: false, scrollPosition: .init())
        }
    }
    
    
    //Select the row that contains the unique object at the specified column, if the object is nil, clear selections
    func selectRow(forUniqueObject obj : Any?) {
        
        guard let delegate = getDelegate() else {
            return
        }
        
        guard let obj = obj else {
            deselectAll()  //not found
            return
        }
        
        for row in 1..<numberOfRows {
            
            let unique = delegate.uniqueObject(forRow : row)  //get the unique object for each row
            
            if delegate.uniqueObjectsAreEqual(obj, unique) {  //objects match - this is the row to select
                selectRow(at: row)
                return
            }

        }
        deselectAll()  //not found
        
    }
    
    
    
    //DeSelect all columns in the row
    func deselectAll() {
        for row in 0..<numberOfRows {
            for col in 0..<numberOfColumns {
                deselectItem(at: IndexPath(row: row, column: col), animated: false)
            }
        }
    }
    
    func getSelectedRow() -> Int? {
        
        if numberOfRows < 1 {  //nothing could be selected
            return nil
        }
        
        for row in 1..<numberOfRows {
            
            let indexPath = IndexPath(row: row, column: 0)
            
            if let cell = cellForItem(at: indexPath) {
                if cell.isSelected {
                    return row
                }
            }
        }
        return nil
    }
    
    
    
    // ----  Do not allow the base class SpreadsheetView to select items - they will be done by the gesture recognizers in this extension -----
    
    public func spreadsheetView(_ spreadsheetView: SpreadsheetView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    public func spreadsheetView(_ spreadsheetView: SpreadsheetView, shouldDeselectItemAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    
}


