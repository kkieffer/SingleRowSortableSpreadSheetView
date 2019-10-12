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
    func longPressDidBegin(at row: Int) //delegate receives notification that a row started a long press,
    func longPressDidEnd(at row: Int)   //delegate receives notification that a row ended a long pressed
    
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
    
    //On row pressed, notify the delegate to sort if tap was on the header, otherwise select the row and let the delegate know
    private func rowPressed(at location: CGPoint) {
        if let indexPath = indexPathForItem(at: location) {
            
            guard let delegate = getDelegate() else {
                return
            }
            
            if indexPath.row == 0 {  //header - sort
                
                var unique : Any?
                if let selectedRow = getSelectedRow() {  //has a selected row
                    unique = delegate.uniqueObject(forRow: selectedRow)  //get a unique object at the selected row
                }
                
                delegate.sortBy(column: indexPath.column)  //tell the delegate to sort its model
                reloadData()  //reload the data from the model
                
                if unique != nil {  //if there was a previously selected row
                    let _ = selectRow(forUniqueObject: unique!)  //now reselect the row with the unique object
                }
            }
                
            else {  //on a row, select it
                selectRow(at: indexPath.row)
                delegate.didSelectRow(at: indexPath.row)
            }
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
        
        //Note: with both a long tap and regular tap recognizer, one or the other might be called on the single tap,
        //depending on whether the OS thinks a long press is starting or a single press occurred.
        //Just having the long press handler is not always enough to recognize a very short tap, but a short tap might
        //also be recognized as starting a long press. So both recognizers are needed and they both call the
        //rowPressed() function so we're guaranteeed to handle the row select. If its a long press, that handler will
        //take care of the ending of the long press
        
    }
    
    
    @objc func handleTap(sender: UITapGestureRecognizer) {
        let location = sender.location(in: self)
        rowPressed(at: location)
    }
    
    
    //On start, handle pressing of the row and notify delegate of the long press start
    //When finished, notify the delegate of the long press end
    @objc func handleLongPress(sender: UILongPressGestureRecognizer) {
        
        guard let delegate = getDelegate() else {
            return
        }

        let location = sender.location(in: self)

        if let indexPath = indexPathForItem(at: location) {

            switch sender.state {
            case .began:
                rowPressed(at: location)
                delegate.longPressDidBegin(at: indexPath.row)
            case .ended:
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
    
    //Deselect all rows, then select all columns in the row
    func selectRow(at row : Int) {
        
        deselectAll()
        for col in 0..<numberOfColumns {
            let ipath = IndexPath(row: row, column: col)
            selectItem(at: ipath, animated: false, scrollPosition: .init())
        }
    }
    
    
    //Select the row that contains the unique object at the specified column, if the object is nil, clear selections
    //Return true if a row was selected, false if all rows are deselected
    func selectRow(forUniqueObject obj : Any?) -> Bool {
        
        guard let delegate = getDelegate() else {
            return false
        }
        
        guard let obj = obj, numberOfRows > 1 else {
            deselectAll()  //not found
            return false
        }
        
        for row in 1..<numberOfRows {
            
            let unique = delegate.uniqueObject(forRow : row)   //get the unique object for each row
            
            if delegate.uniqueObjectsAreEqual(obj, unique) {  //objects match - this is the row to select
                selectRow(at: row)
                return true
            }
            

        }
        deselectAll()  //not found
        return false
    }
    
    
    
    //Deselect all columns in all rows
    func deselectAll() {
        selectItem(at: nil, animated: false, scrollPosition: .init())
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


