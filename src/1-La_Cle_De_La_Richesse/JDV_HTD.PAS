unit jdv_htd;
{
Auteur: Patrick Premartin
Date: Reprise de U_Htd au 07/01/1992.
      09/12/1992.
Langage: Turbo Pascal 6.0
But: Gestion des fichiers .HTD (donn‚es de 'Hyper Text Maker').
}
interface
uses
    u_htp;

const
     max_ecran = 1000;
     c_ch_header = #13'Hyper Text Maker 1.0'#10#13#155' Patrick Premartin 12/1991.'#26;

type
    t_str8 = string [8];

    t_effet = record
                    go_to : word;
    end;

    p_bouton = ^o_bouton;
    o_bouton = object
                     x, y, l : word;
                     effet : t_effet;
                     next : p_bouton;

                     constructor init;
                     constructor load (fich : integer);
                     destructor done;
                     procedure save (fich : integer);
                     procedure active; virtual;
                     procedure unactive; virtual;
                     procedure unactive_all;
                     function suivant : p_bouton;
    end;

    p_txt = ^o_txt;
    o_txt = object
                  ecran : p_page;
                  fich_name : t_str8;

                  constructor init;
                  constructor load (fich : integer);
                  destructor done;
                  procedure save (fich : integer);
                  procedure draw;
    end;

    p_ecran = ^o_ecran;
    o_ecran = object
                    liste_bouton : p_bouton;
                    txt : p_txt;
                    couleur : byte;

                    constructor init;
                    constructor load (fich : integer);
                    destructor done;
                    procedure save (fich : integer);
                    procedure draw;
                    function run (num : word) : word;
                    procedure help_screen;
                    procedure sauver_partie (num : word);
                    function charger_partie : word;
                    procedure lancer_des;
    end;

    p_lst_ecran = ^t_lst_ecran;
    t_lst_ecran = array [1..max_ecran] of p_ecran;

    p_hyper_text = ^o_hyper_text;
    o_hyper_text = object
                         ht : t_lst_ecran;
                         debut : word;
                         ch : string;

                         constructor init;
                         constructor load (nom_fich : string);
                         destructor done;
                         procedure save (nom_fich : string);
                         procedure run;
                         function test : boolean;
    end;

var
   save_name : string;

implementation
uses
    crt,
    u_cache_disk,
    u_codage,
    u_code_clavier,
    u_m_util,
    u_pack,
    u_pile,
    u_sgf;

var
   ht_couleur : byte;
   ht_user : boolean;
   pile : p_pile;

procedure out_of_memory;
begin
     alert ('Out of memory...', al_error);
     alert ('I can continue !', al_error);
     halt (1);
end; { Out_Of_Memory }

{****************************************************************************}

{ Objet : O_Bouton }
constructor o_bouton.init;
begin
     x := 1;
     y := 1;
     l := 0;
     effet.go_to := 0;
     next := nil;
end; { O_Bouton.Init }

constructor o_bouton.load (fich : integer);
begin
     lit_bloc (fich, x, sizeof (x));
     lit_bloc (fich, y, sizeof (y));
     lit_bloc (fich, l, sizeof (l));
     lit_bloc (fich, effet, sizeof (effet));
     lit_bloc (fich, next, sizeof (next));
     if (next <> nil)
     then
         next := new (p_bouton, load (fich));
     {endif}
end; { O_Bouton.Load }

destructor o_bouton.done;
begin
     if (next <> nil)
     then
         dispose (next, done);
     {endif}
end; { O_Bouton.Done }

procedure o_bouton.save (fich : integer);
begin
     ecrit_bloc (fich, x, sizeof (x));
     ecrit_bloc (fich, y, sizeof (y));
     ecrit_bloc (fich, l, sizeof (l));
     ecrit_bloc (fich, effet, sizeof (effet));
     ecrit_bloc (fich, next, sizeof (next));
     if (next <> nil)
     then
         next^.save (fich);
     {endif}
end; { O_Bouton.Save }

procedure o_bouton.active;
var
   nx, ny : byte;
   nc : char;
   i : word;
begin
     nx := x;
     ny := y;
     if ht_user
     then
         inc (ny, 2);
     {endif}
     for i := 1 to l do
         begin
              gotoxy (nx, ny);
              asm
                 push ax
                 push bx
                 push dx
                 mov ah, 08h
                 mov bh, 0
                 int 10h
                 mov nc, al
                 pop dx
                 pop bx
                 pop ax
              end;
              textattr := ((ht_couleur and $0f) shl 4) + ((ht_couleur and $f0) shr 4); { Inverse video }
              gotoxy (nx, ny);
              write (nc);
              inc (nx);
              if (nx > pred (max_col))
              then
                  begin
                       nx := 1;
                       inc (ny);
                       if (ny > pred (max_lig))
                       then
                           ny := 1;
                       {endif}
                  end;
              {endif}
         end;
     {endfor}
end; { O_Bouton.Active }

procedure o_bouton.unactive;
var
   nx, ny : byte;
   nc : char;
   i : word;
begin
     nx := x;
     ny := y;
     if ht_user
     then
         inc (ny, 2);
     {endif}
     for i := 1 to l do
         begin
              gotoxy (nx, ny);
              asm
                 push ax
                 push bx
                 push dx
                 mov ah, 08h
                 mov bh, 0
                 int 10h
                 mov nc, al
                 pop dx
                 pop bx
                 pop ax
              end;
              textattr := ht_couleur xor $08; { Mise en surbrillance }
              gotoxy (nx, ny);
              write (nc);
              inc (nx);
              if (nx > pred (max_col))
              then
                  begin
                       nx := 1;
                       inc (ny);
                       if (ny > pred (max_lig))
                       then
                           ny := 1;
                       {endif}
                  end;
              {endif}
         end;
     {endfor}
end; { O_Bouton.Unactive }

procedure o_bouton.unactive_all;
begin
     unactive;
     if (next <> nil)
     then
         next^.unactive_all;
     {endif}
end; { O_Bouton.Unactive_All }

function o_bouton.suivant : p_bouton;
begin
     unactive;
     suivant := next;
end; { O_Bouton.Suivant }

{****************************************************************************}

{ Objet: O_Txt }
constructor o_txt.init;
begin
     ecran := nil;
end; { O_Txt.Init }

constructor o_txt.load (fich : integer);
var
   nb_txt,
   nb_res : word;
   res : pointer;
begin
     lit_bloc (fich, fich_name, sizeof (fich_name));
     lit_bloc (fich, nb_res, sizeof (nb_res));
     getmem (res, nb_res);
     if (res = nil)
     then
         out_of_memory;
     {endif}
     lit_bloc (fich, res^, nb_res);
     c_codage_1 := $07;
     c_codage_2 := $70;
     ptr_decoder (res, nb_res);
     if (nb_res < sizeof (t_page))
     then
         begin
              unpack (res, pointer (ecran), nb_txt);
              freemem (res, nb_res);
         end
     else
         ecran := res;
     {endif}
end; { O_Txt.Load }

destructor o_txt.done;
begin
     if (ecran <> nil)
     then
         freemem (ecran, sizeof (ecran^));
     {endif}
end; { O_Txt.Done }

procedure o_txt.save (fich : integer);
var
   nb_res : word;
   res : pointer;
begin
     ecrit_bloc (fich, fich_name, sizeof (fich_name));
     pack (ecran, sizeof (ecran^), res, nb_res);
     c_codage_1 := $07;
     c_codage_2 := $70;
     ptr_coder (res, nb_res);
     ecrit_bloc (fich, nb_res, sizeof (nb_res));
     ecrit_bloc (fich, res^, nb_res);
     freemem (res, nb_res);
end; { O_Txt.Save }

procedure o_txt.draw;
var
   i,
   j : byte;
begin
     textattr := ht_couleur;
     clrscr;
     if ht_user
     then
         begin
              writeln;
              for i := 1 to max_col do
                  write (#31);
              {endfor}
         end;
     {endif}
     if ht_user
     then
         gotoxy (1, 3)
     else
         gotoxy (1, 1);
     {endif}
     for j := 1 to max_lig do
         for i := 1 to max_col do
             begin
                  write (ecran^.tab [j, i]);
             end;
         {endfor}
     {endfor}
     if ht_user
     then
         for i := 1 to max_col do
             write (#30);
         {endfor}
     {endif}
end; { O_Txt.Draw }

{****************************************************************************}

{ Objet: O_Ecran }
constructor o_ecran.init;
begin
     liste_bouton := nil;
     txt := nil;
     couleur := $07;
end; { O_Ecran.Init }

constructor o_ecran.load (fich : integer);
begin
     lit_bloc (fich, couleur, sizeof (couleur));
     txt := new (p_txt, load (fich));
     lit_bloc (fich, liste_bouton, sizeof (liste_bouton));
     if (liste_bouton <> nil)
     then
         liste_bouton:= new (p_bouton, load (fich));
     {endif}
     ht_couleur := couleur;
end; { O_Ecran.Load }

destructor o_ecran.done;
begin
     if (txt <> nil)
     then
         dispose (txt);
     {endif}
     if (liste_bouton <> nil)
     then
         dispose (liste_bouton, done);
     {endif}
end; { O_Ecran.Done }

procedure o_ecran.save (fich : integer);
begin
     ecrit_bloc (fich, couleur, sizeof (couleur));
     txt^.save (fich);
     ecrit_bloc (fich, liste_bouton, sizeof (liste_bouton));
     if (liste_bouton <> nil)
     then
         liste_bouton^.save (fich);
     {endif}
end; { O_Ecran.Save }

procedure o_ecran.draw;
var
   i, j : byte;
begin
     if (txt <> nil)
     then
         txt^.draw;
     {endif}
     if (liste_bouton <> nil)
     then
         begin
              liste_bouton^.unactive_all;
              liste_bouton^.active;
         end;
     {endif}
end; { O_Ecran.Draw }

procedure o_ecran.sauver_partie (num : word);
var
   fich : integer;
begin
     fich := ouvre (save_name, ecriture);
     if (erreur_io = 0)
     then
         begin
              ecrit_bloc (fich, num, sizeof (num));
              ferme (fich);
         end;
     {endif}
end; { O_Ecran.Sauver_Partie }

function o_ecran.charger_partie : word;
var
   fich : integer;
   num : word;
begin
     num := 0;
     fich := ouvre (save_name, lecture);
     if (erreur_io = 0)
     then
         begin
              lit_bloc (fich, num, sizeof (num));
              ferme (fich);
         end;
     {endif}
     charger_partie := num;
end; { O_Ecran.Charger_Partie }

procedure o_ecran.lancer_des;
var
   i : byte;
   carac : char;
begin
     randomize;
     while keypressed do carac := readkey;
     repeat
           gotoxy (1, 25);
           i := succ (random (6));
           write ('Appuyez sur une touche pour arr‚ter le d‚s : ', i);
     until keypressed;
     while keypressed do carac := readkey;
end; { O_Ecran.Lancer_Des }

function o_ecran.run (num : word) : word;
var
   bouton_courant : p_bouton;
   carac : char;
   res : word;
   quit : boolean;
begin
     draw;
     bouton_courant := liste_bouton;
     quit := false;
     res := 0;
     while keypressed do
           carac := readkey;
     {endwhile}
     repeat
           carac := readkey;
           case carac of
                carac_nul : case readkey of
                                 touche_f1 : begin
                                                  help_screen;
                                                  draw;
                                                  if (liste_bouton <> nil)
                                                  then
                                                      begin
                                                           liste_bouton^.unactive_all;
                                                           bouton_courant^.active;
                                                      end;
                                                  {endif}
                                 end;
                                 touche_f2 : if confirm ('Sauver cette partie ?')
                                             then
                                                 sauver_partie (num);
                                             {endif}
                                 touche_f3 : if confirm ('Charger une autre partie ?')
                                             then
                                                 begin
                                                      quit := true;
                                                      res := charger_partie;
                                                 end;
                                             {endif}
                                 touche_f4 : while confirm ('Changer la couleur de l''‚cran ?') do
                                                   begin
                                                        ht_couleur := succ (((succ (ht_couleur)) mod 7));
                                                        draw;
                                                   end;
                                 {endwhile}
                                 touche_f5 : if confirm ('Print the screen ?')
                                             then
                                                 asm
                                                    int 05h
                                                 end;
                                             {endif}
                                 touche_f10 : begin
                                                   res := 0;
                                                   quit := true;
                                 end;
                                 touche_home : if (liste_bouton <> nil)
                                               then
                                                   begin
                                                        bouton_courant^.unactive;
                                                        bouton_courant := liste_bouton;
                                                        bouton_courant^.active;
                                                   end;
                                               {endif}
                                 touche_end : if (liste_bouton <> nil)
                                              then
                                                  begin
                                                       bouton_courant^.unactive;
                                                       while (bouton_courant^.next <> nil) do
                                                             bouton_courant := bouton_courant^.next;
                                                       {endwhile}
                                                       bouton_courant^.active;
                                                  end;
                                              {endif}
                end;
                touche_escape : begin
                                     res := 0;
                                     quit := true;
                end;
                touche_return : begin
                                     if (bouton_courant <> nil)
                                     then
                                         res := bouton_courant^.effet.go_to
                                     else
                                         res := 0;
                                     {endif}
                                     if (pile <> nil)
                                     then
                                         pile^.push (num);
                                     {endif}
                                     quit := true;
                end;
                touche_tab : if (bouton_courant <> nil)
                             then
                                 begin
                                      bouton_courant^.unactive;
                                      bouton_courant := bouton_courant^.suivant;
                                      if (bouton_courant = nil)
                                      then
                                          bouton_courant := liste_bouton;
                                      {endif}
                                      bouton_courant^.active;
                                 end;
                             {endif}
                'D',
                'd' : lancer_des;
           end;
     until quit;
     textattr := $07;
     clrscr;
     run := res;
end; { O_Ecran.Run }

procedure o_ecran.help_screen;
begin
     textattr := ht_couleur;
     clrscr;
     textattr := textattr + blink;
     writeln ('            Jeux Dont Vous Etes Le H‚ros.');
     textattr := textattr - blink;
     writeln;
     writeln ('  F1  Affichage de cet ‚cran.');
     writeln ('  F2  Sauvegarde de la partie en cours.');
     writeln ('  F3  Chargement d''une ancienne partie.');
     writeln ('  F4  Change la couleur de l''‚cran.');
     writeln ('  F5  Lance l''impression de l''‚cran. Mettez votre imprimante sur OnLine avant.');
     writeln ('  F10 Quitte le jeu.');
     writeln;
     writeln ('  TAB  vous fait changer de choix.');
     writeln ('  PgUp vous fait choisir la premiŠre option.');
     writeln ('  PgDn vous fait choisir la derniŠre option.');
     writeln ('Appuyez sur <Enter> pour accepter un choix.');
     writeln;
     writeln ('  D vous permet de lancer un d‚s, … utiliser en combat ou en d‚but de partie.');
     gotoxy (10, 24);
     writeln (#155' Patrick Pr‚martin 01/1992.');
     alert ('', al_wait);
end; { O_Ecran.Help_Screen }

{****************************************************************************}

{ Objet: O_Hyper_Text }
constructor o_hyper_text.init;
var
   i : word;
begin
     debut := 0;
     for i := 1 to max_ecran do
         ht [i] := nil;
     {endfor}
end; { O_Hyper_Text.Init }

constructor o_hyper_text.load (nom_fich : string);
var
   i : word;
   fich : integer;
   l : byte;
begin
     met_extension (nom_fich, 'HTD', nom_fich);
     fich := ouvre (nom_fich, lecture);
     if (erreur_io <> 0)
     then
         init
     else
         begin
              lit_bloc (fich, ch [0], 1);
              lit_bloc (fich, ch [1], ord (ch [0]));
              lit_bloc (fich, debut, sizeof (debut));
              i := 1;
              while not (i > max_ecran) do
                    begin
                         ht [i] := nil;
                         inc (i);
                    end;
              {endwhile}
              while not (fin_fich (fich)) do
                    begin
                         lit_bloc (fich, i, sizeof (i));
                         ht [i] := new (p_ecran, load (fich));
                    end;
              {endwhile}
              ferme (fich);
         end;
     {endif}
end; { O_Hyper_Text.Load }

destructor o_hyper_text.done;
var
   i : word;
begin
     for i := 1 to max_ecran do
         if (ht [i] <> nil)
         then
             dispose (ht [i], done);
         {endif}
     {endfor}
end; { O_Hyper_Text.Done }

procedure o_hyper_text.save (nom_fich : string);
var
   i : word;
   fich : integer;
begin
     ch := c_ch_header;
     met_extension (nom_fich, 'HTD', nom_fich);
     cree_bak (nom_fich);
     fich := ouvre (nom_fich, ecriture);
     if (erreur_io = 0)
     then
         begin
              ecrit_bloc (fich, ch, succ (length (ch)));
              ecrit_bloc (fich, debut, sizeof (debut));
              for i := 1 to max_ecran do
                  if (ht [i] <> nil)
                  then
                      begin
                           ecrit_bloc (fich, i, sizeof (i));
                           ht [i]^.save (fich);
                      end;
                  {endif}
              {endfor}
              ferme (fich);
         end;
     {endif}
end; { O_Hyper_Text.Save }

procedure o_hyper_text.run;
var
   ecran_courant : word;
   i : word;
begin
     ht_user := true;
     ecran_courant := debut;
     if (pile <> nil)
     then
         pile^.reset;
     {endif}
     if (test)
     then
         while ((ecran_courant <> 0) and (ht [ecran_courant] <> nil)) do
               ecran_courant := ht [ecran_courant]^.run (ecran_courant);
         {endwhile}
     {endif}
     ht_user := false;
end; { O_Hyper_Text.Run }

function o_hyper_text.test : boolean;
var
   i : word;
   j : word;
   bouton : p_bouton;
   ok : boolean;
begin
     ok := ((debut > 0) and (debut <= max_ecran) and (ht [debut] <> nil));
     for i := 1 to max_ecran do
         if (ht [i] <> nil)
         then
             begin
                  bouton := ht [i]^.liste_bouton;
                  while (bouton <> nil) do
                        begin
                             j := bouton^.effet.go_to;
                             ok := ok and ((j <= max_ecran) and ((j = 0) or (ht [j] <> nil)));
                             bouton := bouton^.next;
                        end;
                  {endwhile}
             end;
         {endif}
     {endfor}
     test := ok;
end; { O_Hyper_Text.Test }

{****************************************************************************}

var
   old_exitproc : pointer;

{$f+}
procedure u_htd_exit;
begin
     if (pile <> nil)
     then
         dispose (pile, done);
     {endif}
     exitproc := old_exitproc;
end; { U_Htd_Exit }

begin
     save_name := '';
     old_exitproc := exitproc;
     exitproc := @u_htd_exit;
     ht_couleur := $01;
     ht_user := false;
     pile := new (p_pile, init);
end. { Fin de l'unit‚ 'JDV_HTD'. }
