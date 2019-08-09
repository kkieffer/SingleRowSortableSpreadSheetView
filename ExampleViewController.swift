//
//  ViewController.swift
//  SpreadsheetView
//
//  Created by Kishikawa Katsumi on 5/18/17.
//  Copyright © 2017 Kishikawa Katsumi. All rights reserved.
//
//  Modified by K. Kieffer to show example use of
//  SingleRowSortableSpreadSheetView.swift
//

import UIKit
import SpreadsheetView

class ViewController: UIViewController, SpreadsheetViewDataSource, SpreadsheetActionsDelegate {
   
    
    @IBOutlet weak var spreadsheetView: SpreadsheetView!
    var header = [String]()
    var data = [[String]]()

    enum Sorting {
        case ascending
        case descending

        var symbol: String {
            switch self {
            case .ascending:
                return "\u{25B2}"
            case .descending:
                return "\u{25BC}"
            }
        }
    }
    var sortedColumn = (column: 0, sorting: Sorting.ascending)
    
    override func viewDidLoad() {
        super.viewDidLoad()

        spreadsheetView.dataSource = self
        spreadsheetView.delegate = self
       
        
        spreadsheetView.addTapAndLongPressGestures(withMinLongPressDuration: 0.3)
        
        spreadsheetView.register(HeaderCell.self, forCellWithReuseIdentifier: String(describing: HeaderCell.self))
        spreadsheetView.register(TextCell.self, forCellWithReuseIdentifier: String(describing: TextCell.self))
 
        let data = try! String(contentsOf: Bundle.main.url(forResource: "data", withExtension: "tsv")!, encoding: .utf8)
            .components(separatedBy: "\r\n")
            .map { $0.components(separatedBy: "\t") }
        header = data[0]
        self.data = Array(data.dropFirst())
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        spreadsheetView.flashScrollIndicators()
    }
    
    
    
    
    //A row was selected by the user
    func didSelectRow(at row : Int) {
        print("Did select row for \(row) \(data[row-1][0])")
    }

    //A long press was finished on the row by the user
    func longPressDidEnd(at row: Int) {
        print("Long press at row \(row) for \(data[row-1][0])")
    }
    
    //Use the String at column 0 as the unique
    func uniqueObject(forRow row: Int) -> Any {
        return data[row-1][0]
    }
    
    func uniqueObjectsAreEqual(_ obj1: Any, _ obj2: Any) -> Bool {
        return obj1 as! String == obj2 as! String
    }
    
    
    
    

    // MARK: DataSource

    func numberOfColumns(in spreadsheetView: SpreadsheetView) -> Int {
        return header.count
    }

    func numberOfRows(in spreadsheetView: SpreadsheetView) -> Int {
        return 1 + data.count
    }

    func spreadsheetView(_ spreadsheetView: SpreadsheetView, widthForColumn column: Int) -> CGFloat {
        return 140
    }

    func spreadsheetView(_ spreadsheetView: SpreadsheetView, heightForRow row: Int) -> CGFloat {
        if case 0 = row {
            return 60
        } else {
            return 24
        }
    }

    
    
    func frozenColumns(in spreadsheetView: SpreadsheetView) -> Int {
        return 1
    }
    
    //The header row is frozen
    func frozenRows(in spreadsheetView: SpreadsheetView) -> Int {
        return 1
    }

    func sortBy(column : Int) {
        if sortedColumn.column == column {
            sortedColumn.sorting = sortedColumn.sorting == .ascending ? .descending : .ascending
        } else {
            sortedColumn = (column, .ascending)
        }
        data.sort {
            let ascending = $0[sortedColumn.column] < $1[sortedColumn.column]
            return sortedColumn.sorting == .ascending ? ascending : !ascending
        }
    }
    
    
    func spreadsheetView(_ spreadsheetView: SpreadsheetView, cellForItemAt indexPath: IndexPath) -> Cell? {
        if case 0 = indexPath.row {
            let cell = spreadsheetView.dequeueReusableCell(withReuseIdentifier: String(describing: HeaderCell.self), for: indexPath) as! HeaderCell
            cell.label.text = header[indexPath.column]

            if case indexPath.column = sortedColumn.column {
                cell.sortArrow.text = sortedColumn.sorting.symbol
            } else {
                cell.sortArrow.text = ""
            }
            cell.setNeedsLayout()
            
            return cell
        } else {
            
            let cell = spreadsheetView.dequeueReusableCell(withReuseIdentifier: String(describing: TextCell.self), for: indexPath) as! TextCell
            cell.label.text = data[indexPath.row - 1][indexPath.column]

            cell.isHighlighted = cell.isSelected
            cell.setNeedsLayout()

                        
            return cell
        }
    }

 
    
    

}
