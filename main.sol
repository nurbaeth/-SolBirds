// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract SolBirds {
    struct BirdShot {
        uint256 angle;      // угол выстрела от 0 до 90
        uint256 power;      // мощность выстрела от 1 до 100
        uint256 damage;     // урон, нанесенный в этом выстреле
    }

    struct Level {
        uint256 hp;                 // "здоровье" цели (структуры)
        uint256 shotsAvailable;     // сколько выстрелов есть у игрока
        bool completed;             // завершен ли уровень
    }

    mapping(address => Level) public levels;
    mapping(address => BirdShot[]) public history;

    event ShotFired(address indexed player, uint256 angle, uint256 power, uint256 damage);
    event LevelCompleted(address indexed player);

    constructor() {}

    function startLevel() external {
        require(!levels[msg.sender].completed, "Already completed");
        levels[msg.sender] = Level({
            hp: 300, // начальное здоровье структуры
            shotsAvailable: 5,
            completed: false
        });
        delete history[msg.sender]; // очистить предыдущую историю выстрелов
    }

    function fire(uint256 angle, uint256 power) external {
        Level storage level = levels[msg.sender];
        require(!level.completed, "Level already completed");
        require(level.shotsAvailable > 0, "No shots left");
        require(angle >= 0 && angle <= 90, "Angle must be between 0 and 90");
        require(power >= 1 && power <= 100, "Power must be between 1 and 100");

        uint256 damage = _calculateDamage(angle, power);
        if (damage > level.hp) {
            damage = level.hp;
        }

        level.hp -= damage;
        level.shotsAvailable -= 1;
        history[msg.sender].push(BirdShot(angle, power, damage));

        emit ShotFired(msg.sender, angle, power, damage);

        if (level.hp == 0) {
            level.completed = true;
            emit LevelCompleted(msg.sender);
        }
    }

    function getHistory(address player) external view returns (BirdShot[] memory) {
        return history[player];
    }

    function _calculateDamage(uint256 angle, uint256 power) internal pure returns (uint256) {
        // Эмпирическая формула "точности" попадания:
        uint256 accuracy = 100 - _absDiff(angle, 45); // максимальная точность при 45°
        return (power * accuracy) / 100; // урон зависит от мощности и точности
    }

    function _absDiff(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a - b : b - a;
    }
}
