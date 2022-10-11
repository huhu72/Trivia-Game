//
//  AnswerCell.swift
//  Trivia
//
//  Created by Spencer Kinsey-Korzym on 5/3/22.
//

import UIKit

class AnswerCell: UICollectionViewCell {
    @IBOutlet weak var answerLabel: UILabel!
    var isCorrectAnswer: Bool!
    var hasBeenSelected: Bool = false
    public func configureAnswer(with answer: String, isAnswer: Bool){
        answerLabel.text = answer
        isCorrectAnswer = isAnswer
    }
}
