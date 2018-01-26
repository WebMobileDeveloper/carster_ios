//
//  searchResultViewController.swift
//  Mycarster
//
//  Created by Shanbo on 1/17/18.
//  Copyright © 2018 Mycarster. All rights reserved.
//

import UIKit

class searchResultViewController: UIViewController,UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var vinNumberLabel: UILabel!
    
    var items:[String:String] = [:]
    var alerts:[String:String] = [:]
    var itemkeys:[String] = ["driven_wheels","gross_weight","curb_weight","fuel_type","engine_name","vehicle_length","vehicle_height","vehicle_width","vehicle_style","vehicle_type","year","make","model","trim","made_in"]
    var alertTitles:[String] = ["hookup_alert", "oilpan_alert","bumper_alert"]
    var vinNumber:String = ""
    override func viewDidLoad() {
        super.viewDidLoad()
        self.vinNumberLabel.text = vinNumber
        
        self.tableView.tableFooterView = UIView()
        
        tableView.estimatedRowHeight = 30
        tableView.rowHeight = UITableViewAutomaticDimension
        
        tableView.estimatedSectionHeaderHeight = 10
        tableView.sectionHeaderHeight = UITableViewAutomaticDimension
        
        tableView.sectionFooterHeight = 0
        
        // Dynamic sizing for the header view
        if let headerView = tableView.tableHeaderView {
            let height = headerView.systemLayoutSizeFitting(UILayoutFittingCompressedSize).height
            var headerFrame = headerView.frame
            
            // If we don't have this check, viewDidLayoutSubviews() will get
            // repeatedly, causing the app to hang.
            if height != headerFrame.size.height {
                headerFrame.size.height = height
                headerView.frame = headerFrame
                tableView.tableHeaderView = headerView
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    @objc func contactButtonTapped(sender: UIButton){
       redirectToURL(scheme: "https://mycarster.com/?page_id=20/")
    }
    @objc func inspectionButtonTapped(sender: UIButton){
        redirectToURL(scheme: "https://mycarster.com/?page_id=75/")
    }
    @objc func visitButtonTapped(sender: UIButton){
        redirectToURL(scheme: "https://mycarster.com")
    }
    
    //MARK: Delegates
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if tableView.isDragging {
            cell.transform = CGAffineTransform.init(scaleX: 1, y: 0.5)
            UIView.animate(withDuration: 0.3, animations: {
                cell.transform = CGAffineTransform.identity
            })
        }
    }
    
    
    //number of  section and row
    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return items.count
        case 2:
            return alerts.count
        default:
            return 0
        }
    }
    
    
    //section header height
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        switch section {
        case 0:
            return 50
        case 3:
            return 70
        case 4:
            return 150
        case 5:
            return 100
        default:
            return UITableViewAutomaticDimension
        }
        

    }
    
    //row height
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    // header of section.
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        switch section {
        case 0:  //item header
            let header = tableView.dequeueReusableCell(withIdentifier: "itemHeaderCell") as! itemHeaderCell
            header.headerTitle.text = "Result For : \(vinNumber)"
            header.selectionStyle = .none
            return header
        case 1:
            let header = tableView.dequeueReusableCell(withIdentifier: "alertHeaderCell") as! alertHeaderCell
            return header
        case 2:
            let header = tableView.dequeueReusableCell(withIdentifier: "alertHeaderCell1") as! alertHeaderCell
            return header
        case 3:
            let header = tableView.dequeueReusableCell(withIdentifier: "inspectionCell") as! inspectionCell
            header.inspectionButton.addTarget(self, action: #selector(inspectionButtonTapped(sender:)), for: .touchUpInside)
            return header
        case 4:
            let header = tableView.dequeueReusableCell(withIdentifier: "contactCell") as! contactCell
            header.contactButton.addTarget(self, action: #selector(contactButtonTapped(sender:)), for: .touchUpInside)
            return header
        default:
            let header = tableView.dequeueReusableCell(withIdentifier: "visitCell") as! visitCell
            header.visitWebsiteButton.addTarget(self, action: #selector(visitButtonTapped(sender:)), for: .touchUpInside)
            return header
        }
    }
    
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if section == 0{
            return 10
        }else{
            return 0
        }
    }
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if section == 0 {
            return UITableViewCell()
        }else{
            return nil
        }
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = indexPath.row
        switch indexPath.section {
        case 0:  // item section cell
            let itemCell = tableView.dequeueReusableCell(withIdentifier: "itemCell") as! itemCell
            itemCell.itemLabel.text = itemkeys[row].replacingOccurrences(of: "_", with: " ").capitalized
            itemCell.valueLabel.text = items[itemkeys[row]]
            if row % 2 == 0 {
                itemCell.backView.backgroundColor = UIColor(red: 215/255, green: 215/255, blue: 215/255, alpha: 1)
            }else{
                itemCell.backView.backgroundColor = UIColor(red: 223/255, green: 240/255, blue: 216/255, alpha: 1)
            }
            
            itemCell.selectionStyle = .none
            return itemCell
        case 2:  // alertCell
            let alertCell = tableView.dequeueReusableCell(withIdentifier: "alertCell") as! alertCell
            alertCell.titleLabel.text = alertTitles[row].replacingOccurrences(of: "_", with: " ").uppercased()
            alertCell.msgLabel.text =  alerts[alertTitles[row]]
            alertCell.selectionStyle = .none
            return alertCell
        default:
            return UITableViewCell()
        }
    }
    
}
