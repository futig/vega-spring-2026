# Problem Set Solutions - Blockchain and DeFi

---

## Problem 1

**Условие задачи:**

Consider a lending pool where one can deposit and borrow USDC and ETH (exp. Compound or AAVE). A user deposits 10000 USDC and uses those as collateral to borrow ETH. Let the initial price be 2000 USDC for 1 ETH, and the liquidation threshold $l = 0.8$.

The user borrows ETH with the loan to value ratio $\beta = 0.5$. Calculate the liquidation price for this position. What happens to the liquidation price if we use $\beta = 0.75$?

---

**Решение:**

$C = 10{,}000$ USDC
$p_0 = 2000$ USDC/ETH
$l = 0.8$
$\beta \in \{0.5,\ 0.75\}$ 

Пользователь занимает не более $\beta$ от стоимости залога в долларовом эквиваленте:

$$\text{Стоимость займа в USDC} = \beta \times C$$

$$\text{Количество занятых ETH} = n_\text{ETH} = \frac{\beta \times C}{p_0}$$

Отношение loan-to-value в момент времени при цене ETH равной $p$:

$$\text{LTV}(p) = \frac{\text{стоимость долга}}{\text{стоимость залога}} = \frac{n_\text{ETH} \times p}{C}$$

Ликвидация наступает, когда $\text{LTV}(p) \geq l$:

$$\frac{n_\text{ETH} \times p_\text{liq}}{C} = l$$

Подставляем $n_\text{ETH} = \frac{\beta \times C}{p_0}$:

$$\frac{\beta \times C}{p_0} \times \frac{p_\text{liq}}{C} = l$$

$$\frac{\beta \times p_\text{liq}}{p_0} = l$$

$$p_\text{liq} = \frac{l \times p_0}{\beta}$$

**Для $\beta = 0.5$:**

$$p_\text{liq} = \frac{0.8 \times 2000}{0.5} = \frac{1600}{0.5} = 3200 \text{ USDC/ETH}$$

**Для $\beta = 0.75$:**

$$p_\text{liq} = \frac{0.8 \times 2000}{0.75} = \frac{1600}{0.75} \approx 2133.3 \text{ USDC/ETH}$$

**Вывод:** при увеличении $\beta$ (большем займе) цена ликвидации снижается и приближается к начальной цене. Это означает, что пользователь берёт на себя больший риск ликвидации при меньшем движении рынка.

---

## Problem 2

**Условие задачи:**

Assume you have 1 ETH in your wallet. How could you double your exposure to ETH dollar price using a lending market? Current ETH price is $p$, the liquidation threshold for ETH is $l$ and max loan to value ratio for ETH is $\beta$. Provide a step by step instruction and calculate the resulting liquidation price. You may assume that all stablecoins are priced perfectly at \$1 and the swap fees are negligible.

---

**Решение:**

Используем лендинговый протокол, где залогом служит ETH, а занимать можно USDC. Схема:

1. Вносим ETH в качестве залога.
2. Занимаем USDC (до $\beta$ от стоимости залога).
3. На занятые USDC покупаем ещё ETH.
4. Вносим новый ETH в качестве залога.
5. Повторяем.

**Пошаговая инструкция**

**Начальное состояние:** 1 ETH, цена $p$ USDC/ETH.

**Итерация 1:**
- Депозит: $1$ ETH (стоимость $p$ USDC).
- Займ: $\beta \cdot p$ USDC.
- Покупка: $\beta \cdot p / p = \beta$ ETH.

**Итерация 2:**
- Депозит: $\beta$ ETH (стоимость $\beta p$ USDC).
- Займ: $\beta^2 \cdot p$ USDC.
- Покупка: $\beta^2$ ETH.

**Итерация $k$:**
- Депозит: $\beta^{k-1}$ ETH.
- Займ: $\beta^k \cdot p$ USDC.
- Покупка: $\beta^k$ ETH.


**Суммарный ETH (залог):**
$$E_n = \sum_{k=0}^{n} \beta^k = \frac{1 - \beta^{n+1}}{1 - \beta}$$

**Суммарный долг в USDC:**
$$D_n = p \sum_{k=1}^{n} \beta^k = p \cdot \frac{\beta(1 - \beta^n)}{1 - \beta}$$

Так как $0 < \beta < 1$, ряды сходятся:

$$E_\infty = \frac{1}{1-\beta} \text{ ETH}, \qquad D_\infty = \frac{\beta \cdot p}{1-\beta} \text{ USDC}$$

Требуем $E_\infty = 2$:

$$\frac{1}{1-\beta} = 2 \implies 1 - \beta = \frac{1}{2} \implies \beta = 0.5$$

При $\beta = 0.5$ за бесконечное количество итераций получим ровно 2 ETH в залоге при долге $p$ USDC (стоимость исходного 1 ETH). Экспозиция к цене ETH - delta = 2.

Ликвидация наступает, когда долг превышает $l$ долю от стоимости залога:

$$D_\infty \geq l \cdot E_\infty \cdot p_\text{liq}$$

$$\frac{\beta p}{1-\beta} = l \cdot \frac{1}{1-\beta} \cdot p_\text{liq}$$

$$\beta p = l \cdot p_\text{liq}$$

$$p_\text{liq} = \frac{\beta \cdot p}{l}$$

$$p_\text{liq} = \frac{\beta \cdot p}{l} < p$$

**Зависимость от параметров:**

| Параметр         | Рост | Эффект на $p_\text{liq}$                                    |
| ---------------- | ---- | ----------------------------------------------------------- |
| $\beta$ (LTV)    | ↑    | $p_\text{liq}$ растёт - ликвидация при меньшем падении цены |
| $l$ (порог)      | ↑    | $p_\text{liq}$ падает - больше буфера до ликвидации         |
| $p$ (цена входа) | ↑    | $p_\text{liq}$ растёт пропорционально                       |

---

## Problem 3

**Условие задачи:**

Consider a Uniswap V2 pool with two tokens, ETH and USDC. Let X and Y be the token amounts. The initial price is $p_0 = 2000$ USDC for 1 ETH. Let a trader swap 50 ETH for USDC in the pool, the swap price is $p_1$.

Let's call $\frac{p_0 - p_1}{p_0}$ the price slippage in the pool for this swap. Calculate the token reserves in the pool to keep the slippage below 0.1% for such swap.

Do such pools exist in real live? Check Defillama or any other suitable analytic instrument to find a DEX pool with reserves greater or equal to what you have calculated.

---

**Решение:**

Цена $p_0 = 2000$ USDC/ETH означает $Y/X = 2000$, то есть:

$$Y = 2000 X, \quad k = X \cdot Y = 2000 X^2$$

Пусть $X$ - неизвестное количество ETH в пуле.

Трейдер продаёт $\Delta x = 50$ ETH в пул (без учёта комиссий по условию задачи):

Новые резервы:
$$X' = X + 50, \quad Y' = \frac{k}{X'} = \frac{2000 X^2}{X + 50}$$

Маргинальная цена после свопа:
$$p_1 = \frac{Y'}{X'} = \frac{2000 X^2}{(X+50)^2}$$

Запишем это через $p_0$:

$$p_1 = p_0 \cdot \frac{X^2}{(X+50)^2}$$

$$\text{slippage} = \frac{p_0 - p_1}{p_0} = 1 - \frac{p_1}{p_0} = 1 - \frac{X^2}{(X+50)^2}$$

Это выражение можно переписать удобнее, обозначив $r = \frac{X}{X+50}$ (доля исходных резервов в новом объёме):

$$\text{slippage} = 1 - r^2 = (1-r)(1+r)$$

Заметим: $r < 1$ всегда, поэтому slippage > 0.

Требуем $\text{slippage} < 0.001$:

$$1 - \frac{X^2}{(X+50)^2} < 0.001$$

$$\frac{X^2}{(X+50)^2} > 0.999$$

Берём квадратный корень из обеих частей (обе стороны положительны):

$$\frac{X}{X+50} > \sqrt{0.999}$$

$$\sqrt{0.999} \approx 0.9994999$$

Решаем неравенство:

$$X > 0.9994999 \cdot (X + 50)$$

$$X > 0.9994999 X + 49.97499$$

$$X - 0.9994999 X > 49.97499$$

$$X \cdot (1 - 0.9994999) > 49.97499$$

$$X \cdot 0.0005001 > 49.97499$$

$$X > \frac{49.97499}{0.0005001} \approx 99{,}930 \text{ ETH}$$

Решение c $\varepsilon$ через формулу:

$$X > \frac{50\sqrt{0.999}}{1 - \sqrt{0.999}} = \frac{50\sqrt{0.999}}{1 - \sqrt{0.999}}$$

Обозначим $\varepsilon = 0.001$ (желаемый slippage). Тогда:

$$X > \frac{50\sqrt{1-\varepsilon}}{1 - \sqrt{1-\varepsilon}} \approx \frac{50(1 - \varepsilon/2)}{\varepsilon/2} = \frac{50 \cdot 2}{\varepsilon} - 50 = \frac{100}{\varepsilon} - 50$$

Для $\varepsilon = 0.001$:

$$X > \frac{100}{0.001} - 50 = 100{,}000 - 50 = 99{,}950 \text{ ETH}$$


$$X \geq 99{,}950 \text{ ETH}, \quad Y = 2000 \cdot X \geq 199{,}900{,}000 \text{ USDC}$$

Используем формулу для стоимости капитала в пуле:

$$V = 2\sqrt{k \cdot p_0} = 2\sqrt{2000 X^2 \cdot 2000} = 2 \cdot 2000 \cdot X \approx 2 \times 2000 \times 99{,}950 \approx \$400{,}000{,}000$$

Для удержания slippage ниже $0.1\%$ при свопе 50 ETH ($\approx \$100{,}000$) нужен пул с TVL не менее $400M.

**Проверка ответа**

Возьмём $X = 100{,}000$ ETH:

$$\text{slippage} = 1 - \left(\frac{100{,}000}{100{,}050}\right)^2 = 1 - \left(0.9995\right)^2 = 1 - 0.99900025 \approx 0.0999\% < 0.1\%$$

На DeFiLlama (defillama.com/dexs) такие пулы существуют. Крупнейшие ETH/USDC пулы на Uniswap V3 (0.05% fee tier) имеют TVL в диапазоне $200–500M, что соответствует нашей оценке. Важно, что в Uniswap V3 ликвидность сконцентрирована в узком ценовом диапазоне, поэтому эффективная глубина значительно выше, чем в V2 при том же TVL.
