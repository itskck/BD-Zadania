--PODZAPYTANIA SKORELOWANE
--------------------------------------------------------------------------------
1.Z którego przedmiotu przeprowadzono najwięcej egzaminów? Podać nazwę przedmiotu
oraz liczbę egzaminów.

select nazwa_przedmiot, count(*) as liczba
from przedmioty p inner join egzaminy e
on p.id_przedmiot = e.id_przedmiot
group by nazwa_przedmiot
having count(*) = (select max(count(*))
from egzaminy e
group by id_przedmiot);

--------------------------------------------------------------------------------
2.Który egzaminator egzaminował najwięcej osób? Podać identyfikator, imię i Nazwisko
egzaminatora oraz liczbę egzaminowanych przez niego osób. Jeśli wynik zawiera wielu
egzaminatorów, uporządkować rezultat według identyfikatora egzaminatora.

select g.id_egzaminator, nazwisko, imie, count(distinct id_student) as liczba
    from egzaminatorzy g inner join egzaminy e
    on g.id_egzaminator=e.id_egzaminator
    group by g.id_egzaminator, nazwisko, imie
having count(distinct id_student)= (select max(count(distinct id_student))
    from egzaminy e
    group by id_egzaminator);

--------------------------------------------------------------------------------
3.W których ośrodkach przeprowadzono ostatni egzamin z poszczególnych przedmiotów?
Dla każdego przedmiotu, identyfikowanego przez nazwę, podać identyfikator oraz nazwę
ośrodka. Dodatkowo wyświetlić datę egzaminu. Uporządkować wynik zapytania według
nazwy przedmiotu.

select nazwa_przedmiot, o.id_osrodek, nazwa_osrodek, data_egzamin
from przedmioty p inner join egzaminy e on p.id_przedmiot=e.id_przedmiot
inner join osrodki o on o.id_osrodek=e.id_osrodek
where data_egzamin=(
    select max(data_egzamin)
    from egzaminy e2
    where e2.id_przedmiot=p.id_przedmiot
    group by id_przedmiot
    );

--KURSORY
--------------------------------------------------------------------------------
4.Wskazać tych studentów, którzy zdawali egzaminy w ciągu trzech ostatnich dni
egzaminowania. W odpowiedzi umieścić datę egzaminu oraz dane identyfikujące studenta
tj. identyfikator, imię i Nazwisko.

DECLARE
    CURSOR c1 IS SELECT DISTINCT data_egzamin FROM egzaminy ORDER BY 1 DESC ;
    CURSOR c2(pdata_egzamin DATE) IS SELECT DISTINCT s.id_student, nazwisko, imie FROM studenci s inner join egzaminy e
                        ON s.id_student = e.id_student
                        WHERE data_egzamin = pdata_egzamin ;
    vstudent VARCHAR2(100) ;
BEGIN
    FOR vc1 IN c1 LOOP
        EXIT WHEN c1%rowcount > 3 ;
        DBMS_OUTPUT.put_line(vc1.data_egzamin) ;
        FOR vc2 IN c2(vc1.data_egzamin) LOOP
                vstudent := vc2.id_student || ' - ' || vc2.nazwisko || ' ' || vc2.imie ;
                DBMS_OUTPUT.put_line(vstudent) ;
        END LOOP ;
    END LOOP ;
END ;

--------------------------------------------------------------------------------
5.Wskazać trzy przedmioty, z których przeprowadzono najwięcej egzaminów. W
odpowiedzi umieścić nazwę przedmiotu oraz liczbę egzaminów.

DECLARE
    CURSOR c1 IS SELECT DISTINCT COUNT(*) exam_n FROM egzaminy e
                 GROUP BY e.id_przedmiot ORDER BY 1 DESC FETCH FIRST 3 ROWS ONLY; 
    CURSOR c2(exam_number INTEGER) IS SELECT e.id_przedmiot id_p, p.nazwa_przedmiot nazwa_p, COUNT(*) e_number 
                                    FROM egzaminy e INNER JOIN przedmioty p ON e.id_przedmiot=p.id_przedmiot
                                    GROUP BY e.id_przedmiot, p.nazwa_przedmiot
                                    HAVING COUNT(*) = exam_number;
BEGIN
    FOR vc1 IN c1 LOOP
        FOR vc2 IN c2(vc1.exam_n) LOOP
            DBMS_OUTPUT.put_line(vc2.id_p || ' ' || vc2.nazwa_p || ' ' || vc2.e_number) ;
        END LOOP;
    END LOOP;
END;

--EXCEPTIONS
--------------------------------------------------------------------------------
6.Podać informację, z których przedmiotów nie przeprowadzono egzaminu. Wyświetlić
nazwę przedmiotu. Uporządkować wyświetlane informacje wg nazwy przedmiotu. Zadanie
wykonać wykorzystując wyjątek systemowy.

declare
    cursor c1 is select id_przedmiot, nazwa_przedmiot FROM przedmioty;
    x number;
begin
    for vc1 in c1 loop
    begin
        select distinct 1 into x from egzaminy e where e.id_przedmiot = vc1.id_przedmiot;
        exception
            when no_data_found then dbms_output.put_line(vc1.nazwa_przedmiot);
        end;
    end loop;
end ;

--------------------------------------------------------------------------------
7.Który egzaminator i kiedy egzaminował więcej niż 5 osób w ciągu jednego dnia? Podać
identyfikator, Nazwisko i imię egzaminatora, a także informacje o liczbie egzaminowanych
osób oraz dniu, w których takie zdarzenie miało miejsce. Zadanie wykonać wykorzystując
wyjątek użytkownika.

DECLARE
my_exception EXCEPTION;
CURSOR c1 IS 
    SELECT e.id_egzaminator idEgzaminator, egz.nazwisko nazwisko, egz.imie imie, e.data_egzamin dataEgz, COUNT(DISTINCT e.id_student) exams_num FROM egzaminy e 
    INNER JOIN egzaminatorzy egz ON e.id_egzaminator = egz.id_egzaminator
    GROUP BY e.id_egzaminator, egz.nazwisko, egz.imie, e.data_egzamin
    ORDER BY 1;
BEGIN
    FOR vc1 IN c1 LOOP
    BEGIN
        IF vc1.exams_num > 4 THEN 
            RAISE my_exception;
        END IF;
        EXCEPTION
            WHEN my_exception THEN
                DBMS_OUTPUT.PUT_LINE(vc1.idEgzaminator || ' ' || vc1.nazwisko || ' ' || vc1.imie || ' ' || vc1.dataEgz || ' ' || vc1.exams_num);
    END;
    END LOOP;
END;
--------------------------------------------------------------------------------
8.Przeprowadzić kontrolę, czy w ośrodku (ośrodkach) o nazwie LBS przeprowadzono
egzaminy. Dla każdego ośrodka o podanej nazwie, w którym odbył się egzamin, wyświetlić
odpowiedni komunikat podający liczbę egzaminów. Jeśli nie ma ośrodka o podanej nazwie,
wyświetlić komunikat o treści "Ośrodek o podanej nazwie nie istnieje". Jeśli w ośrodku nie
było egzaminu, należy wyświetlić komunikat "Ośrodek nie uczestniczył w egzaminach". Do
rozwiązania zadania wykorzystać wyjątki systemowe i/lub wyjątki użytkownika

DECLARE   
    mex1 EXCEPTION;   
    x NUMBER;   
    id NUMBER; 
    nazwa osrodki.nazwa_osrodek%TYPE := 'LBS' ;
    CURSOR c1 IS SELECT id_osrodek FROM osrodki WHERE UPPER(nazwa_osrodek) = 'LBS'; 
BEGIN   
    BEGIN   
    SELECT DISTINCT 1 INTO id FROM osrodki WHERE nazwa_osrodek = nazwa;  
    EXCEPTION  
        WHEN NO_DATA_FOUND THEN RAISE mex1;  
    END;  
    FOR vc1 IN c1 LOOP
                SELECT COUNT(e.id_egzamin) INTO x FROM egzaminy e WHERE e.id_osrodek = vc1.id_osrodek;   
                IF x > 0  THEN 
                    DBMS_OUTPUT.put_line('W ośrodku o ID=' || vc1.id_osrodek || ' odbyło się '|| x ||' egzaminów');  
                ELSE
                    DBMS_OUTPUT.put_line('Ośrodek o ID=' || vc1.id_osrodek || ' nie uczestniczył w egzaminach');  
                END IF;
    END LOOP ;
    EXCEPTION
        WHEN mex1 THEN DBMS_OUTPUT.put_line('Ośrodek o podanej nazwie nie istnieje');   
END;


--FUNKCJE I PROCEDURY
--------------------------------------------------------------------------------
9.Wyświetlić informację o liczbie punktów uzyskanych z egzaminów przez każdego
studenta. W odpowiedzi należy uwzględnić również tych studentów, którzy jeszcze nie
zdawali egzaminów. Liczbę punktów należy wyznaczyć używając funkcji. Jeżeli student
nie zdawał egzaminu, należy wyświetlić odpowiedni komunikat. Zadanie należy
zrealizować, wykorzystując kod PL/SQL.

DECLARE
    x float;
    cursor c1 is select id_student from studenci;
    function points(pid_student varchar2) return float is 
    liczba float;
    begin
        select sum(punkty) into liczba from egzaminy where id_student = pid_student;
        return liczba;
    end points;
begin
    for vc1 in c1 loop
        x := points(vc1.id_student);
        if x is null then
            dbms_output.put_line('Student o id '|| vc1.id_student ||' nie pisal egzaminow.');
        else
            dbms_output.put_line('Punkty studenta o id '|| vc1.id_student ||' = ' || x);
        end if;
    end loop;
end;

--------------------------------------------------------------------------------
10.W tabeli Studenci dokonać aktualizacji danych w kolumnie Nr_ECDL oraz Data_ECDL.
Wartość Nr_ECDL powinna być równa identyfikatorowi studenta, a Data_ECDL - dacie
ostatniego zdanego egzaminu. Wartości te należy wstawić tylko dla tych studentów,
którzy zdali już wszystkie przedmioty. W rozwiązaniu zastosować podprogramy typu
funkcja i procedura (samodzielnie określić strukturę kodu źródłowego w PL/SQL)

DECLARE
    CURSOR c1 is SELECT id_student from studenci for update;
FUNCTION getLiczbaPrzedmiotow return number is
    liczbaPrzedmiotow number;
    BEGIN
        SELECT COUNT(*) into liczbaPrzedmiotow FROM przedmioty;
    RETURN liczbaPrzedmiotow;
END getLiczbaPrzedmiotow;
 
FUNCTION isAllExamPassed(id_stud varchar2) return boolean is
    liczbaZdanychPrzedmiotow number;
    x boolean;
    BEGIN
        SELECT COUNT(zdal) into liczbaZdanychPrzedmiotow FROM egzaminy WHERE id_student = id_stud AND zdal = 'T';
        IF getLiczbaPrzedmiotow() = liczbaZdanychPrzedmiotow then
            x := true;
        else 
            x := false;
        end if;
        RETURN x;
END isAllExamPassed;
FUNCTION getLastExamDate(id_stud number) return date is
    da date;
    BEGIN
        SELECT data_egzamin INTO da FROM egzaminy WHERE id_student = id_stud AND zdal = 'T' ORDER BY 1 DESC FETCH FIRST 1 ROWS ONLY;
    RETURN da;
END getLastExamDate;
 
PROCEDURE updateStudent(id_stud number, data_egz date) is
    BEGIN
        UPDATE studenci SET nr_ECDL = id_stud, data_ECDL = data_egz WHERE id_student = id_stud;
    END updateStudent;
BEGIN
    FOR vc1 IN c1 loop
    if isAllExamPassed(vc1.id_student) then
        updateStudent(vc1.id_student, getLastExamDate(vc1.id_student));
    end if;
    end loop;
END;

--------------------------------------------------------------------------------
11.Utworzyć procedurę składowaną, która dokona weryfikacji poprawności daty ECDL w
tabeli Studenci. Proces ten polegać będzie na sprawdzeniu, czy data ta jest większa od
bieżącej daty systemowej. Jeśli tak, wówczas należy zmodyfikować taką wartość,
wstawiając bieżącą datę systemową do tabeli Studenci.

CREATE OR REPLACE PROCEDURE isECDLCorrect(bool IN OUT BOOLEAN, myDate DATE) IS
BEGIN
    IF myDate > SYSDATE THEN
        bool := TRUE;
    END IF;
END isECDLCorrect;

DECLARE
    bool BOOLEAN DEFAULT FALSE;
    CURSOR c1 IS SELECT id_Student, data_ecdl FROM studenci FOR UPDATE OF data_ecdl;
BEGIN
    FOR vc1 IN c1 LOOP
        bool := FALSE;
        isECDLCorrect(bool, vc1.data_ecdl);
        IF bool THEN
            UPDATE studenci SET data_ecdl = SYSDATE WHERE CURRENT OF c1;
        END IF;
    END LOOP;
END;

--------------------------------------------------------------------------------
12.Utworzyć funkcję składowaną, która będzie kontrolowała proces wprowadzania danych do
tabeli Egzaminy. Funkcja powinna zwrócić wartość FALSE, jeśli podjęto próbę
wprowadzenia egzaminu z przedmiotu, który został już zdany przez studenta. Jako
parametry funkcji przyjąć identyfikator studenta, identyfikator przedmiotu oraz wynik
egzaminu.

CREATE OR REPLACE FUNCTION hasExamPassed(id_stud varchar2, id_przed varchar2, wynik number) RETURN BOOLEAN IS
t NUMBER;
BEGIN
        SELECT 1 into t from egzaminy WHERE id_student = id_stud AND id_przedmiot = id_przed AND zdal = 'T';
    RETURN TRUE;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN RETURN FALSE;
END;


--KOLEKCJE
--------------------------------------------------------------------------------
13.Utworzyć tabelę zagnieżdżoną o nazwie NT_Osrodki, której elementy będą rekordami.
Każdy rekord zawiera dwa pola: Id oraz Nazwa, odnoszące się odpowiednio do
identyfikatora i nazwy ośrodka. Następnie zainicjować tabelę, wprowadzając do jej
elementów kolejne ośrodki z tabeli Osrodki. Po zainicjowaniu wartości elementów należy
wyświetlić ich wartości. Dodatkowo określić i wyświetlić liczbę elementów powstałej
tabeli zagnieżdżonej.

declare
    type recTypeOsr is record ( id number, nazwa varchar2(50)) ;
    type colTypeOsr is table of recTypeOsr ;
    colOsr colTypeOsr := colTypeOsr() ;
    cursor c1 is select id_osrodek, nazwa_osrodek from osrodki order by 1 ;
    i number := 1 ;
begin
    for vc1 in c1 loop
        colOsr.extend ;
        colOsr(i).id := vc1.id_osrodek ;
        colOsr(i).nazwa := vc1.nazwa_osrodek ;
        i := i+1 ;
    end loop ;
    for j in colOsr.first..colOsr.last loop
        dbms_output.put_line(colOsr(j).id || ' - ' || colOsr(j).nazwa) ;
    end loop ;
    
end ;

--------------------------------------------------------------------------------
14.Zmodyfikować kod źródłowy w poprzednim zadaniu tak, aby po zainicjowaniu tabeli
zagnieżdżonej usunąć z niej elementy, zawierające ośrodki, w których nie przeprowadzono
egzaminu. Dokonać sprawdzenia poprawności wykonania zadania, wyświetlając elementy
tabeli po wykonaniu operacji usunięcia. Zadanie rozwiązać z wykorzystaniem
podprogramów PL/SQL.

type recTypeOsr is record ( id number, nazwa varchar2(50)) ;
    type        colTypeOsr is table of recTypeOsr ;
    colOsr      colTypeOsr := colTypeOsr() ;
    cursor c1 is select id_osrodek, nazwa_osrodek from osrodki order by 1 ;
   
    i number := 1 ;
    num number := 0;
begin
    for vc1 in c1 loop
        colOsr.extend ;
        colOsr(i).id := vc1.id_osrodek ;
        colOsr(i).nazwa := vc1.nazwa_osrodek ;
        i := i+1 ;
    end loop ;
    for j in colOsr.first..colOsr.last loop
    select count(1) into num FROM egzaminy WHERE ID_Osrodek = colOsr(j).id;
        IF num < 1 THEN
            colOsr.DELETE(j);
        END IF;

    end loop ;

    for j in colOsr.first..colOsr.last loop
        if colOsr.exists(j) then 
            dbms_output.put_line(colOsr(j).id || ' - ' || colOsr(j).nazwa) ;
        end if;
    end loop ;

end ;


--------------------------------------------------------------------------------
15.Utworzyć tabelę bazy danych o nazwie Indeks. Tabela powinna zawierać informacje o
studencie (identyfikator, Nazwisko, imię), przedmiotach (nazwa przedmiotu), z których
student zdał już swoje egzaminy oraz datę zdanego egzaminu. Lista przedmiotów wraz z
datami dla danego studenta powinna być kolumną typu tabela zagnieżdżona. Dane w tabeli
Indeks należy wygenerować na podstawie zawartości tabeli Egzaminy, Studenci oraz
Przedmioty.

CREATE TYPE Typ_Przed_Obj AS OBJECT (nazwa_przedmiotu VARCHAR2(40), data_zdania DATE) ;
CREATE TYPE Typ_Przed IS TABLE OF Typ_Przed_Obj ;
CREATE TABLE Indeks ( id_student VARCHAR(7),
                        nazwisko VARCHAR(40),
                        imie VARCHAR(40),
                        przedmioty Typ_Przed )
NESTED TABLE przedmioty STORE AS Przedmioty_tabela ;
DECLARE
    i NUMBER := 0 ;
    przed Typ_Przed := Typ_Przed();

    cursor c_student IS SELECT DISTINCT E.id_student, S.nazwisko, S.imie
    FROM Egzaminy E JOIN Studenci S ON S.id_student = E.id_student ;

    cursor c_data (p_IdStud VARCHAR2) IS SELECT P.nazwa_przedmiot, E.data_egzamin 
    FROM Egzaminy E JOIN Przedmioty P ON P.id_przedmiot = E.id_przedmiot WHERE Zdal = 'T' AND E.id_student = p_IdStud ;
BEGIN
    FOR vc1 IN c_student LOOP   
        FOR vc2 IN c_data(vc1.id_student) LOOP
            i := c_data%ROWCOUNT ;
            przed.EXTEND ;
            przed(i) := Typ_Przed_Obj(vc2.nazwa_przedmiot, vc2.data_egzamin) ;
        END LOOP ;
        INSERT INTO Indeks (id_student, nazwisko, imie, przedmioty)
        values (vc1.id_student, vc1.nazwisko, vc1.imie, przed) ;
        przed := Typ_Przed();
    END LOOP ;
END ;

--------------------------------------------------------------------------------
16.Wyświetlić z tabeli Indeks informacje, jakie przedmioty i kiedy zostały zdane przez
poszczególnych studentów. Uporządkować wyświetlane dane wg nazwiska studenta.

SELECT nazwisko, nazwa_przedmiotu as Nazwa_Przedmiot, data_zdania as Data_Zdania 
from indeks, table(przedmioty) 
ORDER BY 1 ;

--------------------------------------------------------------------------------
17.Utworzyć tabelę o zmiennym rozmiarze i nazwać ją VT_Studenci. Tabela powinna zawierać
elementy opisujące liczbę egzaminów każdego studenta. Zainicjować wartości elementów
na podstawie danych z tabel Studenci i Egzaminy. Zapewnić, by studenci umieszczeni w
kolejnych elementach uporządkowani byli wg liczby zdawanych egzaminów, od
największej do najmniejszej. Po zainicjowaniu tabeli, wyświetlić wartości znajdujące się w
poszczególnych jej elementach.

declare
    type typ_rek_stud is record
                         (
                             id_student VARCHAR(7),
                             imie VARCHAR(40),
                             nazwisko VARCHAR(40),
                             liczba_egz number,
                             punkty number
                         );
    type typ_tab_stud is table of typ_rek_stud;
    tab_stud typ_tab_stud := typ_tab_stud();
    
    CURSOR c1 IS 
    SELECT s.id_student idS, s.nazwisko nazwisko, s.imie imie, COUNT(e.id_egzamin) liczbaEgz, COALESCE(SUM(e.punkty), 0) liczbaP 
    FROM studenci s LEFT JOIN egzaminy e ON s.id_student = e.id_student
    GROUP BY s.id_student, s.nazwisko, s.imie ORDER BY 5 DESC;

begin
    for vc1 in c1 loop
        tab_stud.EXTEND ;
        tab_stud(c1%rowcount) := typ_rek_stud(vc1.idS, vc1.nazwisko, vc1.imie, vc1.liczbaEgz, vc1.liczbaP) ;
    end loop ;
    for i in 1 .. tab_stud.count() loop
        dbms_output.put_line(tab_stud(i).id_student || ', ' || tab_stud(i).imie || ', ' || tab_stud(i).nazwisko || ', ' || tab_stud(i).liczba_egz || ', ' || tab_stud(i).punkty);
    end loop;
end ;






-----------------------------------------------------------------
-- ZADANIA ROBIONE PRZEZ NAS

Utworzyć kolekcję typu tablica zagnieżdżona i nazwać ją NT_Studenci. W kolekcji należy
umieścić elementy, z których każdy opisuje studenta oraz całkowitą liczbę punktów
zdobytych przez niego ze wszystkich egzaminów. Do opisu studenta należy użyć jego
identyfikatora, nazwiska i imienia.
Zainicjować wartości elementów kolekcji na podstawie danych z tabel Studenci i Egzaminy.
Zapewnić, by dane umieszczane były w takiej kolejności, aby na początku znaleźli się
studenci, którzy zdobyli największą liczbę punktów.
Po zainicjowaniu kolekcji, wyświetlić wartości znajdujące się w poszczególnych jej
elementach.

DECLARE
    type rowType is record (id_student number, imie varchar(20), nazwisko varchar(20), liczbaPunktow number);
    type tableType is table of rowType;
    NT_Studenci tableType := tableType();

    k number := 0;
    cursor cStudenci is select id_student, imie,nazwisko from studenci;

    function getPointCount(idS studenci.id_student%TYPE) return number is
        n number;
        begin
            n:=0;
            
            select sum(e.punkty) into n from egzaminy e  where idS = e.id_student;
           
            return n;

            Exception
            when no_data_found then return 0;
        end getPointCount; 
BEGIN
    for vcStudenci in cStudenci loop
       NT_Studenci.extend;
       NT_Studenci(cStudenci%ROWCOUNT).id_student := vcStudenci.id_student  ;
       NT_Studenci(cStudenci%ROWCOUNT).imie := vcStudenci.imie;
       NT_Studenci(cStudenci%ROWCOUNT).nazwisko := vcStudenci.nazwisko  ;
       NT_Studenci(cStudenci%ROWCOUNT).liczbaPunktow := getPointCount(vcStudenci.id_student); 
        dbms_output.put_line(NT_Studenci(cStudenci%ROWCOUNT).id_student || ' '|| NT_Studenci(cStudenci%ROWCOUNT).imie || ' ' || NT_Studenci(cStudenci%ROWCOUNT).nazwisko || ' ' || NT_Studenci(cStudenci%ROWCOUNT).liczbaPunktow);
    end loop;
    
END;


--Który student zdawał w jednym miesiącu więcej niż 10 egzaminów? Zadanie należy
--rozwiązać przy użyciu techniki wyjątków (jeśli to konieczne, można dodatkowo zastosować
--kursory). W odpowiedzi proszę umieścić pełne dane studenta (identyfikator, nazwisko, imię),
--rok i nazwę miesiąca oraz liczbę egzaminów.


DECLARE
   
   exc Exception;

   cursor dateCursor is select distinct extract(YEAR from data_egzamin) as yrs from egzaminy order by 1;
   cursor studentCursor is select id_student, imie, nazwisko from studenci;

   procedure isMoreThan10 is
   b boolean;
   howMuch number;
   begin
    for st in studentCursor loop
        for yr in dateCursor loop
            for mo in 1..12 loop
                howMuch := 0;
                select count(*) into howMuch from egzaminy where id_student = st.id_student
                and extract(YEAR from data_egzamin) = yr.yrs 
                and extract(MONTH from data_egzamin) = mo;
                begin
                if howMuch > 8 then
                    raise exc;
                end if;
                EXCEPTION
                    when exc then
                
                    dbms_output.put_line(st.id_student || ' ' || st.imie || ' ' || st.nazwisko || ' ' || yr.yrs || ' ' || TO_DATE(mo,'MM') || ' ' || howMuch);
                end;

            end loop;
        end loop;
    end loop;

   end isMoreThan10;

   begin
    isMoreThan10();
   end;

-- ZADANIA Z KOLOSA 16.01
-------------------------------------------------------------------------------------------------------
Dla każdego roku, w którym odbyły się egzaminy, proszę wskazać tego studenta,
który zdał najwięcej egzaminów w danym roku. Dodatkowo, należy podać sumaryczną liczbę 
punktów uzyskanych z tych egzaminów przez studenta. W odpowiedzi umieścić informację o roku 
(w formacie YYYY) oraz pełne informacje o studencie (identyfikator, nazwisko, imię). Zadanie 
należy rozwiązać z użyciem kursora.

Utworzyć w bazie danych tabelę o nazwie PrzedmiotyAnaliza.
Tabela powinna zawierać informacje o liczbie egzaminów z 
poszczególnych przedmiotów przeprowadzonych w poszczególnych miesiącach dla kolejnych lat.
W tabeli utworzyć 2 kolumny. Pierwsza z nich opisuje przedmiot (nazwa przedmiotu). 
Druga kolumna opisuje rok, miesiąc i liczbę egzaminów z danego przedmiotu w danym miesiącu danego roku. 
Dane dotyczące roku, miesiąca i liczby egzaminów należy umieścić w kolumnie będącej kolekcją typu 
tablica zagnieżdżona. Wprowadzić dane do tabeli PrzedmiotyAnaliza na podstawie danych zgromadzonych tabelach Przedmioty i Egzaminy.
Następnie wyświetlić dane znajdujące się w tabeli PrzedmiotyAnaliza.

Utworzyć kolekcję typu tablica zagnieżdżona i nazwać ją NT_Egzaminatorzy. 
Kolekcja powinna zawierać elementy, z których każdy opisuje egzaminatora oraz liczbę studentów 
przeegzaminowanych przez niego. Do opisu egzaminatora proszę użyć identyfikatora, nazwiska i imienia.
Zainicjować wartości elementów kolekcji na podstawie danych z tabel Egzaminatorzy i Egzaminy. 
Zapewnić, by egzaminatorzy umieszczeni w kolejnych elementach uporządkowani byli 
wg liczby egzaminowanych osób, od największej do najmniejszej 
(tzn. pierwszy element kolekcji zawiera egzaminatora, który egzaminował najwięcej osób). 
Po zainicjowaniu kolekcji, wyświetlić wartości znajdujące się w poszczególnych jej elementach.

Który student nie zdawał jeszcze egzaminu z przedmiotu "Bazy danych"? 
W rozwiązaniu zadania wykorzystać technikę wyjątków (dodatkowo można także użyć kursory).
W odpowiedzi umieścić pełne dane studenta (identyfikator, nazwisko, imię).

Dla każdego ośrodka, w którym odbył się egzamin, wyznaczyć liczbę studentów, 
którzy byli egzaminowani w danym ośrodku w kolejnych latach. 
Liczbę egzaminowanych studentów należy wyznaczyć przy pomocy funkcji PL/SQL. 
Wynik w postaci listy ośrodków i w/w liczb przedstawić w postaci posortowanej wg nazwy ośrodka i numeru roku.

