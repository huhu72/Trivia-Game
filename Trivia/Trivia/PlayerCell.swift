//
//  PlayerCell.swift
//  Trivia
//
//  Created by Spencer Kinsey-Korzym on 5/3/22.
//

import UIKit

class PlayerCell: UICollectionViewCell {
    
    @IBOutlet weak var image: UIImageView!
    @IBOutlet weak var state: UIImageView!
    public func configure(with cell: CategoryItem) {
        image.image = cell.image
        image.tintColor = UIColor.gray
        state.image = cell.state
        state.tintColor = UIColor.orange
       }
}
struct CategoryItem{
    var image: UIImage
    var state: UIImage
}
