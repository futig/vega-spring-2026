# Solidity Syntax Cheatsheet

> pragma solidity ^0.8.26;

---

## Структура файла

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "./OtherContract.sol";

contract MyContract {
    // ...
}
```

---

## Типы данных

### Примитивы

| Тип | Описание | Пример |
|---|---|---|
| `bool` | true / false | `bool isActive = true;` |
| `uint256` | целое >= 0, до 2^256-1 | `uint256 x = 42;` |
| `int256` | целое со знаком | `int256 y = -10;` |
| `address` | адрес аккаунта (20 байт) | `address owner = msg.sender;` |
| `bytes32` | фиксированный массив байт | `bytes32 h = "hello";` |
| `string` | UTF-8 строка | `string s = "hi";` |

> `uint` = `uint256`, `int` = `int256`. Доступны размеры: `uint8`, `uint16`, ..., `uint256` (шаг 8).

### Составные типы

```solidity
// Struct
struct Person {
    string name;
    uint256 age;
}

// Array (динамический)
uint256[] public numbers;
numbers.push(1);
numbers.length;

// Array (фиксированный)
uint256[3] public fixed = [1, 2, 3];

// Mapping
mapping(address => uint256) public balances;
balances[msg.sender] = 100;
```

---

## Виды переменных

```solidity
contract Variables {
    uint256 public stateVar = 1;   // STATE — хранится в блокчейне

    function fn() external view returns (address) {
        uint256 localVar = 42;     // LOCAL — живёт только в функции

        // GLOBAL — информация о транзакции и блоке
        msg.sender;    // адрес вызывающего
        msg.value;     // кол-во wei в транзакции
        block.number;  // номер текущего блока
        block.timestamp; // unix-время текущего блока
        tx.origin;     // адрес исходного инициатора

        return msg.sender;
    }
}
```

---

## Data Locations

| Место | Где живёт | Когда использовать |
|---|---|---|
| `storage` | блокчейн | state-переменные, ссылки на них |
| `memory` | RAM (только в функции) | временные значения, строки/массивы внутри функций |
| `calldata` | входящие данные tx | параметры external-функций (read-only, дешевле memory) |

```solidity
function example(uint256[] calldata input) external {
    uint256[] memory temp = new uint256[](input.length); // memory
    // storage — ссылка на state
    uint256[] storage ref = myStorageArray;
}
```

---

## Видимость (Visibility)

| Модификатор | Доступ |
|---|---|
| `public` | все — снаружи и внутри контракта |
| `external` | только снаружи контракта |
| `internal` | этот контракт + наследники |
| `private` | только этот контракт |

```solidity
function pubFn()  public    {} // + автогенерация геттера для переменных
function extFn()  external  {}
function intFn()  internal  {}
function privFn() private   {}
```

---

## Мутабельность (Mutability)

| Модификатор | Читает state | Пишет state | Принимает ETH |
|---|---|---|---|
| (нет) | да | да | нет |
| `view` | да | нет | нет |
| `pure` | нет | нет | нет |
| `payable` | да | да | **да** |

```solidity
function getX()         external view    returns (uint256) { return x; }
function add(uint a, uint b) external pure returns (uint256) { return a + b; }
function deposit()      external payable { balance += msg.value; }
```

---

## Функции

```solidity
function <name>(<params>)
    <visibility>
    <mutability>
    <modifiers>
    returns (<types>)
{
    // тело
}

// Примеры
function transfer(address to, uint256 amount) external returns (bool) { ... }
function getName() public view returns (string memory) { ... }
```

### Возврат нескольких значений

```solidity
function getInfo() external view returns (address, uint256) {
    return (owner, balance);
}

(address a, uint256 b) = getInfo();
```

---

## Модификаторы

```solidity
modifier onlyOwner() {
    require(msg.sender == owner, "Not owner");
    _; // <-- здесь выполняется тело функции
}

modifier validAmount(uint256 amount) {
    require(amount > 0, "Must be > 0");
    _;
}

// Применение (слева направо)
function withdraw(uint256 amount) external onlyOwner validAmount(amount) {
    // ...
}
```

---

## Конструктор

```solidity
contract MyContract {
    address public owner;
    uint256 public value;

    // Выполняется один раз при деплое
    constructor(uint256 initialValue) {
        owner = msg.sender;
        value = initialValue;
    }
}
```

---

## Наследование

```solidity
contract Base {
    address public owner;
    constructor() { owner = msg.sender; }

    function greet() public virtual returns (string memory) {
        return "Base";
    }
}

contract Child is Base {
    // override переопределяет virtual-функцию
    function greet() public override returns (string memory) {
        return "Child";
    }
}

// Множественное наследование
contract Multi is Base, OtherBase { }
```

---

## Ошибки и валидация

```solidity
// require — проверка условия (откат + сообщение)
require(msg.sender == owner, "Not the owner");

// revert — явный откат с сообщением
if (balance < amount) revert("Insufficient funds");

// assert — инвариант (никогда не должен быть false; если сработал — баг)
assert(totalSupply >= 0);

// Custom error (с 0.8.4, дешевле строк)
error Unauthorized(address caller);
if (msg.sender != owner) revert Unauthorized(msg.sender);
```

---

## События

```solidity
// Объявление (до 3 параметров indexed — для фильтрации)
event Transfer(address indexed from, address indexed to, uint256 amount);

// Эмит
emit Transfer(msg.sender, recipient, 100);
```

- Хранятся в логах транзакции, **не** в storage
- В ~10–50 раз дешевле записи в storage
- Другой контракт не может их читать

---

## Управляющие конструкции

```solidity
// if / else
if (x > 0) { ... } else if (x == 0) { ... } else { ... }

// for (предпочтительнее в продакшене)
for (uint256 i = 0; i < arr.length; i++) { ... }

// while (осторожно — риск упереться в gas limit)
while (condition) { ... }

// Ternary
uint256 max = a > b ? a : b;
```

---

## Работа с ETH

```solidity
// Получить ETH
function deposit() external payable {
    // msg.value — кол-во wei
}

// Отправить ETH
payable(recipient).transfer(amount);          // откат при ошибке
(bool ok, ) = recipient.call{value: amount}(""); // рекомендуемый способ
require(ok, "Transfer failed");

// Баланс контракта
address(this).balance;
```

---

## Интерфейсы

```solidity
interface ICounter {
    function increment() external;
    function getCount() external view returns (uint256);
}

// Использование
ICounter counter = ICounter(contractAddress);
counter.increment();
```

---

## Полезные глобальные функции

```solidity
keccak256(abi.encodePacked(a, b));  // хэш
abi.encode(...);                    // ABI-кодирование
abi.decode(data, (uint256, address)); // декодирование
block.timestamp;                    // unix time в секундах
type(uint256).max;                  // максимальное значение типа
```
