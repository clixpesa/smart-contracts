// SPDX-License-Identifier: Apache 2.0
pragma solidity 0.8.19;
import "hardhat/console.sol";

library CalcTime {
    uint constant SECONDS_PER_DAY = 24 * 60 * 60;
    int constant OFFSET19700101 = 2440588;

    /// @dev should return next timestamp from given schedule and day of week
    /// @param _schDay 1 Monday
    function _nextDayAndTime(
        string memory _schDay,
        string memory _schOccur
    ) internal view returns (uint256 nextTimeStamp) {
        uint256 day;
        uint256 month;
        uint256 year;
        uint256 _ocurrance = _getOcurranceNo(_schOccur);
        if (_ocurrance == 1) {
            return block.timestamp + SECONDS_PER_DAY;
        } else {
            uint256 _day = _getDayNo(_schDay);
            uint256 _days = block.timestamp / (24 * 60 * 60);
            uint256 dayOfWeek = ((_days + 3) % 7) + 1;
            (year, month, day) = _daysToDate(_days);
            if (_ocurrance == 7) {
                uint256 nextDay = day + ((7 + _day - dayOfWeek) % 7);
                nextTimeStamp =
                    _daysFromDate(year, month, nextDay) *
                    SECONDS_PER_DAY;
                if (nextTimeStamp <= block.timestamp) {
                    nextTimeStamp = nextTimeStamp + (7 * SECONDS_PER_DAY);
                }
                return nextTimeStamp;
            } else if (_ocurrance == 28) {
                uint256 nextDay = day + ((28 + _day - dayOfWeek) % 28);
                nextTimeStamp =
                    _daysFromDate(year, month, nextDay) *
                    SECONDS_PER_DAY;
                if (nextTimeStamp <= block.timestamp) {
                    nextTimeStamp = nextTimeStamp + (28 * SECONDS_PER_DAY);
                }
                return nextTimeStamp;
            } else {
                return 0;
            }
        }
    }

    /// @dev return number of day from given day of week
    /// @param _day 1. Monday
    function _getDayNo(
        string memory _day
    ) internal pure returns (uint256 dayNo) {
        string[7] memory weekList = [
            "Monday",
            "Tuesday",
            "Wednesday",
            "Thursday",
            "Friday",
            "Saturday",
            "Sunday"
        ];
        bytes32 encodedElement = keccak256(abi.encode(_day));
        for (uint256 i = 0; i < weekList.length; i++) {
            if (encodedElement == keccak256(abi.encode(weekList[i]))) {
                return i + 1;
            }
        }
        return 0;
    }

    /// @dev return number of ocurrance from given ocurrance
    /// @param _ocurrance 1. Daily 7. Weekly 28 Monthly
    function _getOcurranceNo(
        string memory _ocurrance
    ) internal pure returns (uint256 ocurranceNo) {
        string[3] memory ocurranceList = ["Daily", "Weekly", "Monthly"];
        uint8[3] memory ocurranceSize = [1, 7, 28];
        bytes32 encodedElement = keccak256(abi.encode(_ocurrance));
        for (uint256 i = 0; i < ocurranceList.length; i++) {
            if (encodedElement == keccak256(abi.encode(ocurranceList[i]))) {
                return ocurranceSize[i];
            }
        }
        return 0;
    }

    function _daysFromDate(
        uint year,
        uint month,
        uint day
    ) internal pure returns (uint _days) {
        require(year >= 1970);
        require(month > 0 && month <= 12);
        require(day > 0 && day <= 31);
        int _year = int(year);
        int _month = int(month);
        int _day = int(day);

        int __days = _day -
            32075 +
            (1461 * (_year + 4800 + (_month - 14) / 12)) /
            4 +
            (367 * (_month - 2 - ((_month - 14) / 12) * 12)) /
            12 -
            (3 * ((_year + 4900 + (_month - 14) / 12) / 100)) /
            4 -
            OFFSET19700101;

        _days = uint(__days);
    }

    function _daysToDate(
        uint _days
    ) internal pure returns (uint year, uint month, uint day) {
        require(_days >= 0);
        int __days = int(_days);

        int L = __days + 68569 + OFFSET19700101;
        int N = (4 * L) / 146097;
        L = L - (146097 * N + 3) / 4;
        int _year = (4000 * (L + 1)) / 1461001;
        L = L - (1461 * _year) / 4 + 31;
        int _month = (80 * L) / 2447;
        int _day = L - (2447 * _month) / 80;
        L = _month / 11;
        _month = _month + 2 - 12 * L;
        _year = 100 * (N - 49) + _year + L;

        year = uint(_year);
        month = uint(_month);
        day = uint(_day);
    }
}
