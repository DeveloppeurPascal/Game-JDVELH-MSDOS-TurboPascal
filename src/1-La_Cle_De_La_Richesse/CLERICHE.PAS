program La_Cle_De_La_Richesse;
{
Auteur: Patrick Pr‚martin.
Date: 07/01/1992.
      09/01/1992.
Langage: Turbo Pascal 6.0
}
uses
    crt,
    u_msg,
    olf_software,
    jdv_htd,
    u_m_util;

const
     num_vers : string [3] = '1.0';
     dat_vers : string [10] = '01/09/1992';

var
   ht : p_hyper_text;

begin
     repeat
     until (set_langue (msg_f) or true);
     save_name := 'CLERICHE.GAM';
     ht := new (p_hyper_text, load ('CLERICHE'));
     init_licence ('JDVELH1');
     init_olf_message (mess_freeware);
     init_olf_software ('La Cl‚ de la Richesse ('+num_vers+').', #155' Patrick Pr‚martin '+dat_vers);
     repeat
           ht^.run;
     until (not confirm ('Voulez-vous rejouer ?'));
     dispose (ht, done);
end.
