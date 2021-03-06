with Ada.Text_IO;
with AWS.MIME;
with AWS.Parameters;
with AWS.Status;

with Email;
with Keys;
with Server;
with Tokens;
with Util;

use type AWS.Status.Request_Method;

package body VKS with SPARK_Mode => Off is

   function Build_HTML_Answer (S : String) return Response.Data;

   -----------------------
   -- Build_HTML_Answer --
   -----------------------

   function Build_HTML_Answer (S : String) return Response.Data is
   begin
      return Response.Build
        (MIME.Text_HTML,
         "<!DOCTYPE html>" &
           "<html>" &
           "<head>" &
           "<script src=""https://code.jquery.com/jquery-1.10.2.js""></script>" &
           "<link rel=""stylesheet"" href=""/style.css"">" &
           "</head>" &
           "<body>" &
           "<div id=""nav-placeholder""> </div>" &
           "<script> $(function(){ $(""#nav-placeholder"").load(""/nav.html""); }); </script>" &
           S &
           "</body>" &
           "</html>");
   end Build_HTML_Answer;

   --------------------
   -- By_Fingerprint --
   --------------------

   function By_Fingerprint (Request : Status.Data) return Response.Data is
   begin
      if Status.Method (Request) /= Status.GET then
         raise Constraint_Error;
      end if;

      return Response.Build
        (MIME.Text_HTML, "<p>WIP on GET by-fingerprint</p>");
   end By_Fingerprint;

   --------------
   -- By_Keyid --
   --------------

   function By_Keyid (Request : Status.Data) return Response.Data is
   begin
      if Status.Method (Request) /= Status.GET then
         raise Constraint_Error;
      end if;

      return Response.Build
        (MIME.Text_HTML, "<p>WIP on GET by-keyid</p>");
   end By_Keyid;

   --------------
   -- By_Email --
   --------------

   function By_Email (Request : Status.Data) return Response.Data is
      use Email;
      use Keys;

      P : constant AWS.Parameters.List := AWS.Status.Parameters (Request);
      E : Email_Id;
      K : Key_Id;
   begin
      To_Email_Id (AWS.Parameters.Get (P, "email"), E);
      if E /= No_Email_Id then
         K := Server.Query_Email (E);
         if K /= No_Key then
            return Build_HTML_Answer
              ("<p> The key is " & To_Key_String (K) & "</p>");
         end if;
      end if;
      return Build_HTML_Answer
        ("<p> Key not found</p>");
   end By_Email;

   ------------
   -- Upload --
   ------------

   function Upload (Request : Status.Data) return Response.Data is
      P : constant AWS.Parameters.List := AWS.Status.Parameters (Request);
      E : Email.Email_Id;
      Key : Keys.Key_Id;
      Token : Tokens.Token_Type;
      Keytext : constant String := AWS.Parameters.Get (P, "keytext");
      Addr : constant Util.String_Lists.List := Util.Extract_Email (Keytext);
   begin
      for S of Addr loop
         Ada.Text_IO.Put_Line (S);
      end loop;
      Email.To_Email_Id (Addr.First_Element, E);
      Keys.To_Key_Id (Keytext, Key);
      --  check for valid email
      pragma Assert (E in Email.Valid_Email_Id);
      Server.Request_Add (E, Key, Token);
      declare
         L : constant String :=
           "<a href=""/vks/v1/request-verify?token=" & Tokens.To_String (Token)
           &"""> Link to validate the token</a>";
         S : constant String :=
           "This is the confirmation link to verify the add." &
           " Normally we would send it by email, but this is just a demo.";
      begin
         return Build_HTML_Answer
           ("<p>" & S & "</p>" & "<p>" & L & "</p>");
      end;
   end Upload;

   --------------------
   -- Request_Verify --
   --------------------

   function Request_Verify (Request : Status.Data) return Response.Data is
      P : constant AWS.Parameters.List := AWS.Status.Parameters (Request);
      Token : constant Tokens.Token_Type :=
        Tokens.From_String (AWS.Parameters.Get (P, "token"));
      Status : Boolean;
   begin
      Server.Verify_Add (Token, Status);
      if Status then
         return Build_HTML_Answer
           ("<p>Successfully added key</p>");
      else
         return Build_HTML_Answer
           ("<p>Error when adding the key</p>");
      end if;
   end Request_Verify;

end VKS;
