//
// Created by Артём Семёнов on 21.10.2021.
//

import Foundation

public enum MAAWErrors : String, Error {
    case appDoesNotHaveWindows = "This app doesn't have windows"
    case falePIDInitialise = "fale PID initialise"
}
