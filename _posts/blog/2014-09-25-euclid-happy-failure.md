---
layout:     blogpost
title:      "Не совсем удачный генератор ритма"
date:       2014-09-25 03:00:00
categories: blog
author:     "OSCII"
permalink:  /rhythm-happy-failure.html
---

Пару дней назад примерно в час ночи, — в это время я обычно сижу за
компьютером, — на меня нахлынуло непреодолимое желание переделать реализацию
генератора [эвклидовых ритмов](http://www.youtube.com/watch?v=UNbNv6J_w_Q).
Мне не нравится, что все везде секвенция сначала создается в виде массива из нулей
и единиц (единица — удар, ноль — тишина), который надо где-то сохранить и
затем делать lookup его элементов. Мне хотелось сделать некое подобие
[чистой функции](http://habrahabr.ru/post/149086/):
на вход подается число, символизирующее номер шага, а на выходе единица или ноль;
что именно — определяется на основании параметров ритма без генерации
промежуточного массива. Забегая вперед, скажу, что я так и не воспроизвел
работу оригинального алгоритма, но то, что получилось в итоге, — своего рода
глитчевый, некорректно работающий алгоритм, — определенно интересно
и достойно статьи.

## Эвклидовы ритмы

После выхода статьи [1] в интернете поднялась немаленькая шумиха вокруг т.н.
«эвклидовых» ритмов. А все потому, что с их помощью них легко сгенерировать
музыкальный ритм, который звучит естественно. В той же статье приводятся примеры,
как с помощью этого алгоритма симулировались тардиционные ритмы, в т.ч. из джаза,
этнической музыки и т.д. Примеры звучания можно легко найти на YouTube.

Алгоритм, принимая в качестве входных параметров длину секвенции (в шагах)
и количество ударов, генерирует ритм, пытаясь расположиить все удары максимально
равномерно по всей секвенции. Если количество ударов кратно количеству шагов,
то проблем не возникает, все удары могут быть легко расположены по секвенции
равномерно. Например, для четырех ударов на 16-ти шагах секвенция будет
выглядеть так: `[4, 16]: 1000100010001000`. Однако, не так очевидно, как
равномерно расположить уже 5 шагов на тех же 16-ти шагах:
`[5, 16]: 1000100100100100`. Или `[3, 7]: 1010100`. Грубо говоря, этот алгоритм
генерирует музыкально звучащие сбивки.

Кому интересно, можете поиграться с классической реализацией, например,
с помощью [Max4Live девайса](http://cycling74.com/project/euclidean-rhythm-generator/).

Хочу отметить, что алгоритм, используюемый автором, был разработан
для ускорителя нейторонов [2], высоковольный источник питания которого работает
лучше, когда в него подаются электрические импульсы с интервалами,
равномерно распределенными по времени при работе ускорителя.

## Принцип работы

Для краткости, объясню работу алгоритма на примере. Допустим, мы хотим сгенерировать
секвенцию, длиной 11 шагов, 4 из которых — удары. Вот так это будет работать:

```
Ритм [4, 11]

Шаг 1   Шаг 2       Шаг 3         Шаг 4
10      100 |       10010 || <=   10010100100
10      100 | <-    100           Результат
10      100 |       100
10      10  || =>
0  |
0  | -> Переносим эту группу чисел вверх
0  |
```

То есть мы последовательно переставляем элементы из конца в начало,
в итоге получая ритм _(шаг 4)_. Я себе поставил задачу реализовать данный
алгоритм без проведения таких итераций. На вход алгоритм будет принимать номер
шага, а на выходе `0` и `1` из ритма. В приведенном примере, алгоритм должен
преобразовать число `3` в `1`, `7` в `0` и т.д.

## Моя попытка

Как завещали там математики [3], решение любой задачи надо
начинать с анализа частных случаев. Поэтому возьмем для начала простейший
случай, когда количество ударов кратно длине секвенции, например
`[4, 12]: 1000100010001000`, и «нарисуем» ритм таким образом:

```
1 0 0 0
1 0 0 0
1 0 0 0
1 0 0 0
```

Здесь мы расположили числа так, чтобы единицы были в первом столбце.
В этом случае наш ритм можно представить как матрицу размером `4х4`,
где значение элементов с координатой `X = 0` равно `1`. В этом случае,
определение значения элемента сводится нахождению координаты `X` и сравнения ее
с нулем. Это просто. Я даже приведу примеры кода на Python:

```python
def get_step(i, p, s):
  z = s - p     # Определяем количество нулей в секвенции
  w = math.ceil(float(z) / p) + 1     # Определяем ширину матрицы
  X = i % w     # Находим координату X
  if X == 0:
    return 1
  else:
    return 0
```

где `X,Y` — координаты, `i` — индекс элемента, `p` — количество ударов, `s` —
длина секвенции. Возможно, стоит пояснить, как вычислялась ширина матрицы.
Ширина матрицы складывается из количества столбцов с нулями + 1 столбец единиц.
Количество столбцов с нулями можно определить, разделив количество нулей на
количество единиц: мы как бы распределяем нули равномерно по всем строкам матрицы.
Если результатом деления оказывается не целое число, мы округляем в большую сторону:
этот факт символизирует о том, что последний столбец короче предыдущих.

Однако, этот метод будет постоянно нам генерировать ритмы, в которых удары
равномерно распределены по секвенции. Поэтому рассмотрим следующий пример, ритм
`[5, 18]`:

```
0 ->  1 0 0 0 <- 3
      1 0 0 x <- 7
      1 0 0 0
      1 0 0 x
      1 0 0 0 <- 17
```

Здесь с помощью `x` помечены места, где должен был бы быть ноль в случае
с «равномерным» ритмом, а стрелочки указывают на порядковый номер (индекс)
элемента. Обратите внимание, что длина строк в ритме равна либо `3`, либо `4`,
и эти длины чередуются.

Сейчас неясно, как же делать lookup по таблице, что мы использовали в прошлом
примере. Давайте представим, что отсутствующих нулей вовсе нет, и у нас
имеется все та же матрица. Тогда нам надо определенно избегать попадания
в «несуществующие» элементы. Но как? У нас же на входе последовательность чисел,
и, если пользователю придется самому следить на использованием «несуществующих»
элементов, то весь смысл теряется.

А если, после попадания на несуществующий элемент, увеличивать индекс,
поданный на вход, и делать lookup заново?

Хмм, это может сработать. Тогда надо определить, сколько несуществующих точек
мы уже было, чтобы добавить к нашему индексу. Я для этого использовал формулу
`i / (2w - 1)`. Оглядываясь назад, я понимаю, что она некорректна, но это не
важно — на текущий момент я этого не знаю. И так, обновим наш Python код:

```python
def get_step(i, p, s):
  z = s - p
  w = math.ceil(float(z) / p) + 1
  ii = i + i / (2 * w - 1)  # Обновленный индекс
  if ii % w == 0:           # X теперь вычисляется тут
    return 1
  else:
    return 0
```

## Результаты

Посмотрим примеры того, что генерирует наш код:

```
[4,13]  1 0 0 0 0 0 0 1 0 0 0 0 0
[5,18]  1 0 0 0 0 0 0 1 0 0 0 0 0 0 1 0 0 0
[11,18] 1 0 0 1 0 0 1 0 0 1 0 0 1 0 0 1 0 0
[2,31]  1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
[3,31]  1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0
[4,31]  1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1
[5,31]  1 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0
```

Не очень секси, правда? А может, заменим в функции `get_step()` ширину на высоту?
Мне кажется, я чувствую себя достаточно креативно для этого.
Высота у нас определяется количеством единиц:

```python
def get_step2(i, p, s):
  z = s - p
  w = p
  ii = i + i / (2 * w - 1)
  if ii % w == 0:
    return 1
  else:
    return 0
```

```
[4,13]  1 0 0 0 1 0 0 1 0 0 0 1 0
[5,18]  1 0 0 0 0 1 0 0 0 1 0 0 0 0 1 0 0 0
[11,18] 1 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0
[2,31]  1 0 1 1 0 1 1 0 1 1 0 1 1 0 1 1 0 1 1 0 1 1 0 1 1 0 1 1 0 1 1
[3,31]  1 0 0 1 0 1 0 0 1 0 1 0 0 1 0 1 0 0 1 0 1 0 0 1 0 1 0 0 1 0 1
[4,31]  1 0 0 0 1 0 0 1 0 0 0 1 0 0 1 0 0 0 1 0 0 1 0 0 0 1 0 0 1 0 0
[5,31]  1 0 0 0 0 1 0 0 0 1 0 0 0 0 1 0 0 0 1 0 0 0 0 1 0 0 0 1 0 0 0
```

Так-то лучше! Намного интереснее на мой взгляд.

Хоть и алгоритм работает совершенно некорректно, в нашем случае это
даже неплохо. У нас получился не использующий рандом
генератор паттернов, который вполне можно использовать в своих патчах.

## Заключение

Ну что, время для работы над ошибками? Нет, как-нибудь в другой раз.
Это увлечение и так переросло из формата «перед сном» в формат «статья на Pattr».
Может быть, однажды, возможно даже зимой, я продолжу эту тему.
Если, конечно, никто из друзей или читателей не захочет продолжить это
забавное начинание...

Тестовый код на Python и патч для Max/MSP можно найти после референсов.


## Референсы

1. Toussaint, Godfried. _“The Euclidean algorithm generates traditional musical
rhythms.”_ Renaissance Banff: Mathematics, Music, Art, Culture.
Canadian Mathematical Society, 2005.
2. Bjorklund, Eric. _“The theory of rep-rate pattern generation in the SNS timing
system.”_ SNS ASD Tech Note, SNS-NOTE-CNTRL-99, 2003.
3. Knuth, Donald and Erwin, Ronald Graham and Oren Patashnik.
_“Concrete Mathematics: A Foundation for Computer Science.”_
Massachusetts: Addison-Wesley, 1989.


## Код

### Max/MSP

```
<pre><code>
----------begin_max5_patcher----------
2775.3oc6cszjiZqEds6eEbckT0LY7LAIdIeqJKtKytTUVN0TcgsU6lDL3Bv
yz2IUxu8.RBa.id.FvP2rXXbyKczmN5HoO8cr+qGVrbS3K33kZ+WsOqsXwe8
vhEjSkchEr+dwxCtur02MlbaKCveKbyerbE8RI3WRHmNV6vgC4mM3zgvSI93
DxinyN6Q2jsO6Er+wH71DZQZZa9I8UZPGqOYsRyRm7GoG09B6Y71Qd6ok3GM
Lye8OEFjD3d.Stz+Kxy0O+JaC8CinuZ8OYXYirMVk9IGGnk45rOgbzsPnUZf
BkQ1qK166jWG.9I8KUBuf75.H6b+8COjcXkhHE966b29OMFSfEgDSqr+H6Xs
PhQ9aeSXzNbTopu0pBGJVeKUwfsnhs20KfS8BJsdAry9O.An0LfbpXvkmeQQ
oszI3nGwAta7wEAOZ4l7+OhokvxXu8AYNCZK8BRK07W7wHbLNHwMwKLnnyGh
XB5DHVmc3tiRHj5vDbcWBS2bMlSngiZO6l7ws9gw35gCfT3.fHNO1qEEf.hj
GffSecdPjLWHCfAwhLsk6CUpVhiX3HCHSsLOe7WwQwoEPg6dwR2iGKb5EEdj
Lz+On82sWc9TdAzSANepH7W8xedz4y5Fkh0Io0jSQTb5Ej8R5ESaweH+QuzP
PZA.qI8V.PheIDhtTaS8N16Gt8Ow6J37kBsGwAdAEwuRWdG9I2S9IOVeCS4q
+j6VL2Gt116EK2G4sKLHyHJ8jYmNu39rFwGqTUgb8.2i07nwo0hSwabixPUV
WMX9ESBC8KeoyMjo8cbC7N3lfS7nlJT+7K06vwHRmwBEDsm7ywaiB88K8pnW
4q0bkcos0aweyaWxyj2UQfL818Nl2.r7LBsyaONNo74Rb2GW9LklmPQmvhAE
Jc9JAGHcDxecbiAvKN.KbH4HzJ+341qJQBPEKmq5aWLn20cS0KbgsgGNfCXX
S9oIAEYcSZIVTJPYk4Qg80.7gInJvDafM6pAKqBSNEKG98g3G2rd7ciav9rA
WD.xvNDLokOeHSWMOKjZtV1K4Um.2WGme5et0NWTGlz4ZXI1swpebapLja+5
zH.HCB8hwsGLscHfoNY3RSo8AMuSfInCAyC33X283ZQSP1LhRgC8az6DQlbk
EEbQ7wSi9AOu+tk9dAh7JUZfAlWo7QF.8pW4J1XDMCSuL4rLnfybQHU8rqWO
XGGdJZat0vbWzJiBoySJwK37DU+7Y.ox88r2tckmYHcxTwYSMiNEXkbLZpEa
pnEmFkVCLJrXPCr3wAFaonEaOZrXGEsXiQiEiTzhc5HKV6KOTbssKic+Jd2i
okPZLxGcSRh71bJgFVo3xxu00eJe8sMXYY0ZDBJbdEZ55z235yHh37yVyp+d
3BH1PtfHK3Ood9dL4y2ikNgPE.k8SCwreku9kqGnIuzoK1aU0SHgfFx893N2
D2BCxblzkzmYCtBEKWt2Tq9bX57a8rYXu570sq65.zka.3T6cXV3Np8c.0ub
GPX14SB2u2GW3cPLjyDHdloxr4XDStAXFC4jIbkeiFPg2Hqy0k.C0fVvgGsr
kAVEeE2Avh9olxxJqNzPhkY8rff0x2pEnsblTEw3rprrx5bVZxf299tHjFZB
cdMlEZyhjPiDBcl8GIzyzIOSm7LcxyzIOSm7LcxyzIOSm7aX5j6F1jAyrIOy
lbGxl7Pyo0aQdCmdbyN83+d5sGCC893Lyl7fxlbNqbMj2Fl7hAHm7IgJf3l1
I4TAzI2cTWkZMQgZV5sE.flFDR+Dybkd2wbk.F8ZivRyW+SUb42yLkVp4bSh
2fgoHHA.aMjvUywr4yCTWvnOEseCi8kND69sS9woAnZL5QYCfwLfiPzynyQO
GBr43LTfGm9iQ7S1A4ZY1p.oJbgtANWG3uBE9Jelt3IfBsEcHxuM7TPZj4zw
vAZnFu6hrV.1QfvV.qtKZHaaNx+mJ4lPN7ZtVN7ZMbahjoNMqTnKeV33of64
dHwK9ADQRFFkh9NbnpwZ3kXpRPUmQHpBrTNpbGtcdt+Yii.y.ZZ++qYlrDP2
gIShpHnR816zDyYON4w3D7Q36deqSMG5zpAPCg9sq61vopF+DoPOc3jdmTsb
n7uYyxlM5No5XNuSpy6j5PrgWrz5j8eR2vK3ncGu9keQq8aq.SgHzwWLrjwH
Nrm1zKw6E8.s2B+3shh15psygPyoNJVdw4kgQOu1uIzzwD.P5Hzqk5N1M6yE
2dyUVDd+6Bhe4Xj1O3Az9.43Oq8Nn1Ok9Qn1G0.u+V8OYvpETJtBlz6enHuy
u0dmSqBSBWAeS8WY9lIOGcp8aeMc11rUv.jtyqnA2ADLPNfGuAGPyK7vI2AD
XMEc.EIhhe.bq9eVEz1iH8S.Ld0F.7WC1geo09fzU5CPWXSSjKn8TzCTD38a
YTTEq8tv.b7JsL688su6L86HGJVx3it+kH0.Cl2nbWYbznndWgKaYeugPrq2
FRjuBC0.Bv.I72dQLR.k0DAZ7HUFUUPU1R+FKo2px1LXzXyPUcMLlbpnBNdR
UaHnIdyiDaVUseAGOxUCppl.g1yx+ZJJ+qNU+OPcck0+Cn06Z03WIOrzYTIk
7nOlvgtUTNlppIGznQRNiTw0Xpp1ZbFFo0buDICvDnpHYl14YcKgGHRU0tX9
ZLMzagtUXPlJ5VA1GxVo+EfRazehYCjeROo9jWQ5HwPmNE.GXAcjX.gy5HYV
GIpskWEGNn44T3ZJmbzuxerjRItQC1VPAiQzJsAHOiC6xMA6FwUZ1NfzUCVg
n2JvZ2H6IZzx23xdBxVK8rrmtITTGMK6oNQ1SN1yxdpGj8DCVmk8zsH6I1WK
JuA08zGztYYmn72oL8ktmFECz7yosYcj.xjCj8zWpSO4G5NFFso8pHCBHIU9
rJxZiSHx3B18pWEYB5JeTaK1y+lCKx9UhRtSHb3kCZ0ZvEhwJiYbIHiGIYUd
75HKiCgY7IMSFwYkHOqZhXY3PaEHgVcnyYxpRqQ8bno.OZpvklT9zTjSMA7p
oB2ZR3WSJGaR3YSJWa73aSLmah4cSL2aB4eiGGb0yCW8bwU0WuZnmqttLxND
OdmReueUOoGhTaovnC74+nTX3xghuUbopXBEGBV124ipiJFUKSElfjPIFdWP
uqFXqxFxGdJXWGAtT9KMqMgGDIeU4CzIYvNEFvSvrGtef+Gx9c+ri.e1W.rH
U.eP+C9pz0PTKP4AptRwsW2vTmdzpo4QtJKEHMMyZu2ZUmFeEp0H2s1VqLZP
sBLYpUfFTqf8TsJ+GFfJSxTl5BqNO5tZFfpMayVLoGtFlDCRjgHVEh0oDwxM
.8LOCe+V4MTYdFdsQa3+4icYxpIB5Pul2Vk4zUaNc0lSWs4zUazltZJm3IYJ
+YpkSRn2v4JyazbRZBl6WSxrub5kVfSwDFE.mfISrp+3FTSkar+qhJX77SHg
54Ytyb9O2+lLZNEWGSo3Jokn77joILS01eVZybc6doo6xaNwklDw0s3W2ZeU
B7np8fTvbbFLqg7axpTzwXvrGC3T0d.ir1qAxdTwcthQ2q1ioJ3CbvrGfJsW
U.wdEerUwdzGN+mrPcPY1i8v0doB7LbCV.gp1bMPviJc2I97Ci6CPE2YhQOP
1iip1i9HBexX8wbXrGKU8eFH7wTU7YXrGkbeFLqwVwopNL9NpzTAGUXCb3FF
UQ+l1XMzUfUQ.wYFREACWQnvWKPXdBCNsb96G9W.FYiQK
-----------end_max5_patcher-----------
</code></pre>
```

### Gist

<script src="https://gist.github.com/oscii/e6775172138652fef1b4.js"></script>
