program Comment_Prevenir_Les_Maitres;
{
Auteur: Patrick Pr‚martin.
Date: 24/06/1992.
Langage: Turbo Pascal 6.0
}
uses
    crt,
    olf_software,
    jdv_htd,
    u_msg,
    u_m_util;

const
     num_vers : string [3] = '1.0';
     dat_vers : string [10] = '07/14/1992';

var
   ht : p_hyper_text;

begin
     repeat
     until (set_langue (msg_f) or true);
     save_name := 'COMPREMA.GAM';
     ht := new (p_hyper_text, load ('COMPREMA'));
     init_licence ('JDVELH3');
     init_olf_message (mess_freeware);
     init_olf_software ('Comment pr‚venir les MaŒtres ? ('+num_vers+')', #155' Patrick Pr‚martin '+dat_vers);
     repeat
           ht^.run;
     until (not confirm ('Voulez-vous rejouer ?'));
     dispose (ht, done);
end.
