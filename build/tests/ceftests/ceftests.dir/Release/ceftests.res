        ��  ��                  �      �� ���    0 	        <html>
  <head><title>OSR Test</title></head>
  <style>
  .red_hover:hover {color:red;}
  #li { width: 530px; }
  body {background:rgba(255, 0, 0, 0.5); }
  input {-webkit-appearance: none; }
  #LI11select {width: 75px;}
  #LI11select option { background-color: cyan; }
  .dropdiv {
    width:50px;
    height:50px;
    border:1px solid #aaaaaa;
    float: left;
  }
  #dragdiv {
    width: 30px;
    height: 30px;
    background-color: green;
    margin: 10px;
  }
  #draghere {
    position: relative;
    z-index: -1;
    top: 7px;
    left: 7px;
    opacity: 0.4;
  }
  #touchdiv, #pointerdiv {
    width: 100px;
    height: 50px;
    background-color: red;
    float: left;
    margin-left: 10px;
  }
  </style>
  <script>
  function getElement(id) { return document.getElementById(id); }
  function makeH1Red() { getElement('LI00').style.color='red'; }
  function makeH1Black() { getElement('LI00').style.color='black'; }
  function navigate() { location.href='?k='+getElement('editbox').value; }
  function load() {
    var elems = [];
    var param = { type: 'ElementBounds', elems: elems };

    elems.push(getElementBounds('LI00'));
    elems.push(getElementBounds('LI01'));
    elems.push(getElementBounds('LI02'));
    elems.push(getElementBounds('LI03'));
    elems.push(getElementBounds('LI04'));
    elems.push(getElementBounds('LI05'));
    elems.push(getElementBounds('LI06'));
    elems.push(getElementBounds('LI07'));
    elems.push(getElementBounds('LI08'));
    elems.push(getElementBounds('LI09'));
    elems.push(getElementBounds('LI10'));
    elems.push(getElementBounds('LI11'));
    elems.push(getElementBounds('LI11select'));
    elems.push(getElementBounds('email'));
    elems.push(getElementBounds('quickmenu'));
    elems.push(getElementBounds('editbox'));
    elems.push(getElementBounds('btnnavigate'));
    elems.push(getElementBounds('dropdiv'));
    elems.push(getElementBounds('dragdiv'));
    elems.push(getElementBounds('touchdiv'));
    elems.push(getElementBounds('pointerdiv'));

    if (window.testQuery)
      window.testQuery({request: JSON.stringify(param)});

    fillDropDown();
  }

  function fillDropDown() {
    var select = document.getElementById('LI11select');
    for (var i = 1; i < 21; i++)
      select.options.add(new Option('Option ' + i, i));
  }

  function getElementBounds(id) {
    var element = document.getElementById(id);
    var bounds = element.getBoundingClientRect();
    return {
      id: id,
      x: Math.floor(bounds.x),
      y: Math.floor(bounds.y),
      width: Math.floor(bounds.width),
      height: Math.floor(bounds.height)
    };
  }

  function onEventTest(event) {
    var param = 'osr' + event.type;

    if (event.type == "click")
      param += event.button;

    // Results in a call to the OnQuery method in os_rendering_unittest.cc.
    if (window.testQuery)
      window.testQuery({request: param});
  }

  function onFocusTest(ev) {
    if (window.testQuery)
      window.testQuery({request: "osrfocus" + ev.target.id});
  }

  function allowDrop(ev) {
    ev.preventDefault();
  }

  function drag(ev) {
    ev.dataTransfer.setData("Text",ev.target.id);
  }

  function drop(ev) {
    var data=ev.dataTransfer.getData("Text");
    ev.target.innerHTML = '';
    var dragged = document.getElementById(data);
    dragged.setAttribute('draggable', 'false');
    ev.target.appendChild(dragged);
    if (window.testQuery)
      window.testQuery({request: "osrdrop"});
  }

  function selectText(ev) {
    var element = ev.target;
    var selection = window.getSelection();
    var range = document.createRange();
    range.selectNodeContents(element);
    selection.removeAllRanges();
    selection.addRange(range);
  }

  function onTouchEvent(ev) {
    var param = 'osr' + ev.type;
    // For Touch start also include touch points.
    if (event.type == "touchstart")
      param += ev.touches.length;
    // For Touch Move include the touches that changed.
    if (event.type == "touchmove")
      param += ev.changedTouches.length;

    // Results in a call to the OnQuery method in os_rendering_unittest.cc.
    if (window.testQuery)
      window.testQuery({request: param});
  }

  function onPointerEvent(ev) {
    var param = 'osr' +  ev.type + ' ' + ev.pointerType;
    if (window.testQuery)
      window.testQuery({request: param});
  }

  </script>
  <body onfocus='onEventTest(event)' onblur='onEventTest(event)' onload='load();'>
  <h1 id='LI00' onclick="onEventTest(event)">
    OSR Testing h1 - Focus and blur
    <select id='LI11select'>
      <option value='0'>Default</option>
    </select>
    this page and will get this red black
  </h1>
  <ol>
  <li id='LI01'>OnPaint should be called each time a page loads</li>
  <li id='LI02' style='cursor:pointer;'><span>Move mouse
      to require an OnCursorChange call</span></li>
  <li id='LI03' onmousemove="onEventTest(event)"><span>Hover will color this with
      red. Will trigger OnPaint once on enter and once on leave</span></li>
  <li id='LI04'>Right clicking will show contextual menu and will request
      GetScreenPoint</li>
  <li id='LI05'>IsWindowRenderingDisabled should be true</li>
  <li id='LI06'>WasResized should trigger full repaint if size changes.
      </li>
  <li id='LI07'>Invalidate should trigger OnPaint once</li>
  <li id='LI08'>Click and write here with SendKeyEvent to trigger repaints:
      <input id='editbox' type='text' value='' size="5" onfocus="onFocusTest(event)"></li>
  <li id='LI09'>Click here with SendMouseClickEvent to navigate:
      <input id='btnnavigate' type='button' onclick='navigate()'
      value='Click here to navigate' /></li>
  <li id='LI10' title='EXPECTED_TOOLTIP'>Mouse over this element will
      trigger show a tooltip</li>
  <li id='LI11' onclick='selectText(event)'>SELECTED_TEXT_RANGE</li>
  <li><input id='email' type='text' size=10 inputmode='email'></li>
  <li id="quickmenu">Long touch press should trigger quick menu</li>
  </ol>

  <div class="dropdiv" id="dropdiv" ondrop="drop(event)" ondragover="allowDrop(event)">
    <span id="draghere">Drag here</span>
  </div>
  <div class="dropdiv">
    <div id="dragdiv" draggable="true" ondragstart="drag(event)"></div>
  </div>
  <div id="touchdiv" ontouchstart="onTouchEvent(event)" ontouchend="onTouchEvent(event)" ontouchmove="onTouchEvent(event)" ontouchcancel="onTouchEvent(event)">
  </div>
  <div id="pointerdiv" onpointerdown="onPointerEvent(event)" onpointerup="onPointerEvent(event)" onpointermove="onPointerEvent(event)" onpointercancel="onPointerEvent(event)">
  </div>
  <br />
  <br />
  <br />
  <br />
  <br />
  <br />
  </body>
</html>
  �       �� ���    0 	        <html>
<head>
<title>PDF Test</title>
</head>
<body bgcolor="white">
<iframe src="pdf.pdf" width="500" height="500"></iframe>
<iframe src="pdf.pdf" width="500" height="500"></iframe>
</body>
</html>
�u      �� ���    0 	        %PDF-1.4
%äüöß
2 0 obj
<</Length 3 0 R/Filter/FlateDecode>>
stream
x���Mk1���>v*ɒ?`hڤ�۶=���$P��䒿_���n��,;c�,�yeK30�v���|*��ܗ+�ۡ������I���S�\�za����Wm)NŲ��԰q��e�W�Fh�@2Y���"L��d!�EB�YHlD��K2Y8��c1YX���L6e��f0YBN���c
�8^��"��د?��[I~��:.4A��\�q��=�N{��]�!�fYv�˷���Y���}]*dV�5+�-+:§nc��%���У z�_�s7֙x3��f�<O#��l�K�Nx��/C�����A][��Ǩ�h�٥����8DQ�AݺM"r �0&ZJ-��D�f��~HFES��;&Z�h�qL4'͒�D3�h8(Ӡh�=	`�G��u7H9�s��o[%=^#�p]��VEߟ]���Ef�m�:�[O���c#@�����_�/�Z���h�~���n����C��N�&{�� u��
endstream
endobj

3 0 obj
496
endobj

5 0 obj
<</Length 6 0 R/Filter/FlateDecode>>
stream
x�u�;1��������������+�b�,����Q��df��#AM�Pw��<1��0��n�W�0^�2+��#���0�	��|�'$ᄌ��F�^���Z��	�F�L�!o�&��d���}�q�]5���ɼ��p]3���2���٠)��byg�Nh$_���EA
endstream
endobj

6 0 obj
177
endobj

8 0 obj
<</Length 9 0 R/Filter/FlateDecode>>
stream
x�uP�
1��[w��@H��
������	����fs��H`23dvؠ&x�;`9�|`��j����E�.j�;�<�'X��u)qDƶF�E��r{��q;�!5T�wj���Sd��:m��,qͮ+�e:�75�F܈&[�Ig�a�in�-�aCٳ�\,��u��A�
endstream
endobj

9 0 obj
177
endobj

12 0 obj
<</Length 13 0 R/Filter/FlateDecode/Length1 31040>>
stream
x���{\T��8>3�잽���,����(
(�DaU�\D0RYa5����&�f�&MҾ�5ML�����&6m�X�&MߦibSs}c�ך&Q��̜s�%1}�������7{��gf��y�g��9�o	!B�o
����v)B�E���}�tǻ7��I������ߴ�g!�+EH������ZҮ)DH�&�_�;�եV�.�w(��	�'�Z@2:7^��dX�"ȷu�������!�=�l
^޷R�����!/�7���y�e�3j�z�F��6ͥ�}����g�@�!�P���Z�'��
:��h2[������@��|4Q�d�c(��"'B�S�=�NtEޣ�4% �ڍ��]�)t=��@�=� C�FT�~��D�C;�����Q=<(�N���|���C�8�DW��(;#�kЍ����FdF�P�C��6�,��Fo�ףb���><i���3��1:��:rQ2j��x�#ͿG^Gӡ�]�^�&�S��a�!��7ԏ��ZyY�(HGۀU���(�A�!�.v�+�r��G�p�`�P+�D���x6^B�5�#Ց�(Ƹz���������װIs&�H�JBy��3�~��r��XH\�A%PӋ~�~�^��ҫ1i
4~��WP<��V ��A�w��jx���G!��;����8��Z�DrH/���G:q<��}������DNp?��ЦN��X`E�����/�f*�|~����5��-�{���� ��[h�=�>�v</Ǘ�N|%މ������K�=RF�F�1��m�~�/�������ܢ}o�y����&>�Dv�� ��w��af�	�'x�Doa6b<N�+��߆ƻ��xFy	���ǟ��/�GKRH:�����m�{��</��g�������\)���U;�]�����'�'��@s���n͓�g4g�&�:ҽx�Gr/�1�&n��{btb,�W� k�\p�R�>�X�A�����	x��s��8�o�������}�ǌ������?⏁f3q1�g��d���[$D6�]�N2F^%�sg�\��-�Z�7�m����܋�_���s�yx"��w��x/���k�-�������՚4ok�M��q�
s�B��\h�����@:�E��ӱ{����>t;)��o�oA�נ�������&r#�˵��|\���^��s�r���qn@�,�7m<�$����4��[��r�	_M>֚�(F���%7��q/�׸7��?�����&�qu ?�h�Q:�C�Sn3�
�#�_�n9��O�^h��\q������m$��N�>�	}w�����_��E�®���hs�	�7��&qx�q�]	���&݀[����?�-�o@op?�O��r��M=�pځ6G�E�5����z��&�ɟ�v%W��Czh�ՠ����>z����'H�2���!���<HP���~�ƴ�d��X0h��&�Ѫȣ���z��M}�3r%�����@���F}(v�x�f19�Y�N�ɟH�{���3�} �O!�@s�Dha���@��A�ދ֢K�)��G0�R�(*��!#��\��M�<�Xč�3ҍj�a�cA����8���6
��� ��>�\���������_���q�ʦ�e��.)�?�dn��Y3�gL����dgy33<��%wZ�+%9��HL����D��l2�:A��9�Q^���M
{�¼׳t�t��� S���h�T����Ф��~�\�%L���bbQ*E���G
��H�x��f�o��H���f�.�NO�R��Y!�q�/��9h���F��rOy�0=�� 
;<}#ر 3�8�Fҙ��p��"N�TP
�\f ��[��HIOo����ힵa�Y��
*gÄ��a�#u�٠[����÷��hm������ns�:���V�W�rNf�s{y����n8��hvxx�~pyslm:�[Z�hK2�/��o&V5H0���9�o�!%::+y~!O���m��z�"O���6X���0�ߞ>���?9���pc�'=�0���p�ģ���{��R�Ԛ�y#�Mf�Ū &s,��1��S��>�YL)�T�@��v	(i�����(4��4��`h��
��ۆ�y���k2E�4�w�9��Ԓ�R����(H�$*jP��a�/��KED(�5����y[ǉ��'J� �P�6�2/؟�N��q?Z����f9/��)�ȟ�k	�6ZsT�IXAk�Ԛh�6H���:o��*&�:�q�?���U��嫚��p��۪�)9�~n�N��q��\
Q �±Z��Qd�i6��L��2��t ��K��b�R9n1������#gh+�L6S���M�ϟ��B�i���jV5�6L�Q��T�x�؜.���
ؙ��39:�����XVN@��"%;1E�[�C�sz�bPt�Ë=�����xdh�G=��3��@�*8㑃���������`S�hăoZ>��75�j> g3���Q�Iyۢ���k> �~g����B��hUa��(�1��~��X-�
X�}#V�S�0j'r�(�e���k�����C�N.���lԈ�� ہX���ʩ��9V��^�+}�&2\� �F+sS1�mƞ����#�g�ɳ=
=a	 ��%���a	���,Ǵ
繠����Z7���ɚ�)[��.����}[�F���:\�����a|��#d���a�^=�ʓz3���Y���� ��C)���!^4NCZ4F�)�0N���!�C�?�Q�N�9E�����09}���5�����h!��y�f�L���2!°��%��y�}�$�(=��_� �9t~���L��?�$��V0� ��؏��|'@#��
��d�Q��~����~K���������'{%��?��0��0�>�%�o<��(�d�Y��G>3��֘�̀�P����P z����r��>���YN��#������1�� {f�'��H�D*?<��1?�����?��gr#��?A�I��q|�M�>�s -���EB#w�d��Đl��*���z��^/��IlV�sc��Ω��\���cz}���������j�����SgX}X�s��gO����`/ɇ��dmt~rx��8?�;�����&�d��P�:�.����L.�̆�"�@fe�1p�
�59Ee�I*�@���#�E��c`W���cM�SaQ,��v���y>3k6W�*�*�e�wE���EX��2��8���	ep�
d��W�T��x/#�@�
xU ���S(��� \V�k��"3��Jj���6n0o���9��0_a�Jܒ1���6�l��&ޘq}�滭w'��h�V�OO��S��zo�"��l�fyQ��y����SHJf�yzZV&��$j�#g�&*������D-<���f/i��$��fw�䟖�����٨Iw����n�M�řӠD9ez��
��8�t"���$�i��%\^Rޅ�x����iR\ܢt` ��Ls�����21rv��-�>�ItQ����o�{Q��|0f��9t>F:XNrA�I�tu����t��oa�}<�!keWw	 ��[is{#�LI�����Z}
��i�4�5t��VS��i`�~���S4:K9esPΕ` [f�D��'5������4RX0g��"o�7#��]4gNaAb�C�z=Ӵ	�Dޑg*��3-û�i�__��DC����˻�_���~���A�S��*����<tŎ/��W�u/���s��E��G�W��P�/:�^��r���^V[X�1{���[N��q?����ȉZȶ1�T�U񗉗��FS��bA'UQHg����.�=fi����m�{u�"��((���X'��:�Nv*w�d)�O�Ӭ*7��\�r3���M^ud��_T�%�_=��A�)�ms++b�)kp�ۘoE���
i$!���� �Wɓ~?ɹ���Ζ�&~3q����[�ͺa�f�A�=�ӡ�~��[�Y}}�Y�fp֊R�t�]r�r��ML�"�c
71�t �d��nrx%=v����z���J�Y��NU��l>Ey/ +��N|���*�by��Pɶ�T�ì����s�A��it���&9��Dk4�f�MH�O�K�)�#�-9u�t�h��Þ ��k���DG�V�B<���s���?{r��-�5W|���#��;?���~w�S/j&�.[;q��c���3+����|��s��~#����?�Y�;5�`|(�HH�����~I('�"��Я�������e[������I�B��󞺰��\G �f��{�J6�D������"����7>��&�-���޹����HN�ϔ��9�d�ij��:�Y��5�E�f�f���$�Q�@�0��ա7���KP�q��X�TX����T����c����-1���!�qk���RP�ʇznSܶB[���3���/�|��%��A��M��\��kI�'�(�9UB���p��^;������^{�U�bT�8���=��_��҂�y��"���ðF���i�~��Kg元56)k,�Ш����U�"��|�:h�Vu�PP��ϣ̢�cM�I{�nC ��(�$���
��b��T�����6VSî�����$�Jՙ�*<�d��1�D�N�MR�d�3�(�oDg�O�#�:d(5~]pA˖�ņ��+c& xv��M2�G�,"�8�ϧ������I+h��j@�IK��d�4�6��@��l��}����W������|Çz&��(~��5��9r��2��6�NNK)8Ɏ<�
ب�һӋDWjV���vg�Z�>N��O�kx�k�z�EgQ/�t)�TK�ru>K�-��ͷTpK�~�ZWe,�.�]j��Zo�(t��۷k�u�����~��6ڲQ�9˒mͲ���E��m��{��û�n㣦}h��������?���߳�k?��\�2j)�&�,����b��%�,Vގl:A�)X3-�L�,gƦL�x�U1�f��s)��8>Nk0ڼ����7��uۮ��6�!L�C^�IVS���$�w6_v
�S���j�I��s�
�Fo0��PD��:�ګAvi<R�_g�Z�gm�Nlv�O#�k4��9�l�7�-:���3��9���czS�;���L3#�n6������[�g�?'�q���<d�@���Z�5\c �q�¯���^�56b�9���m�>͐t0~l>wn3[I�g[[�Z7�Or����D�rL�:���X��z�o�U�v�p~5��i�	��
�Pv7�Iy�_��y�,�$r8rl�I��/���V	<��x��i�
E��xiD��YyzCU�p���ʓ#�$Wڡ2-�z�o��ా4*̤Ì���<|t�hsGls[��^��K���I ������^�� ��+�I��Z~s�r(��
F
M�|_�Iǅq�9�qC�=\��&||!_���f_���ء�s��{/����y�s���u_�F��w��p!ډ�#e���H�ԋ�A{� �?�?t�E�����gva���Ǐ���E˹�(��w�mF�&>Ϙ�����S�R���<O�qN�����MB�������	�����Y˲v�=�'�I���0o�qqz �1�1�KhOo�i��{-��<g��ڄq22���8y�/Jh&jC}hE/!��������\&CbBaf���I�� ����Qş�d�t:_r`��w�9�|�d�"�y�;���aۨwh�ё�����7RA��4�3�z�D5���c� �c���V����U[��)�ŭ8�&w��	�ֈ�w[Zk��U=�ZE���dg���&S`�F���(EV�{ɔk�/o0���	�W��ySN��X�j�\�
N�������/���);m�㬃���ς#)�]d��cv��Q�q��t8���c,(��&�o��L��n;|ţ�??���}��+w?u�廛��gt�*߂K�rƷ�3t~�?N\�$����G^|��g��UD��@��(	��?�I�����Jmh�BI��.�LK�KuM��zm�NW$γ�K���U��Ās�f��^l��&�;7i6�;�M�M��m8A�՘/�5���L�\H2t�/؀��S�)>�~">*MbS|F
��?]������Q)=3F���jX�
@W��Z22�f
	� 	�pH�V�7	��L�)�-N��آ��E�,]��&��&�?��11��EIA�-[��i�b��;ꇡ�h!�ߤ��~顆]��Y�EŊ�u�}T���>8\�N��3�i�C��V���_ߠiЯլ��ʋ�A��|�b��⑛�g������͉�Fw��{��Q��n�:�����:���/����~���T�]Q1;��%��s:s:u?��Oo���8r!��H�Uu�9�l��u�mV৛4s(���x�|
*�-�3g��4����LpY5n��75|-Dg4������o \&��f=�ԟP8����� $�:<�xz�S��S��B<[w[�x��:���ܑ�z9�70��_Rsy�X����I�[_����c�EP��4ؽ	(�;�ȕ@Vp��V�
c�ۨ�Շ�����)��<寧P���Y�?i>�?��ϲ�K��*�W'����W'ջ��M�A����ΑsN%b���KlK�K�]�]�"E>�e�A���Q�v-i�31�wŹx#��9�5�0�K-���י�m�ϝZ
|�Xf���r��flNv������i�A�؝xH���M���N���y������[�
����}'�;��k���t=S,l.�:�JIJ��s��(�b8e�}�s�6R��:M�Ġ�ٍÅͥ��&߄Q/ds?v�=ilP[���H7'N��1Ӵܷ�}t����q���|�=����^x�,7�m����q��Gc؍9l��oL|&J{v�v�w>
��.�w�$����Q��Ae�^�QƩ����.��+����C��e���ؒ ��N���1㟬��)7����Q��f�L�/ћ��UW�h�kp�ŵ9~@~��g~D|$٤3'6�.n�f����p4��7�3�M;L#�e�k�����k��dw�oم�mz��jD�4���2C�q����6Y3���cʹ��4�(��2�>7�@�����ï�*�W�����A�"v�����R	��t\�JP�J�*�	�QIoJ�8!`*�D>�@`W��j4�+��XT��nfV"�UZ��W��.����g���g�bi+�[O��U�Ӣxƪ\2Od��
'W:���O_�������zݽ'�U7=��n�7:�>�S��'�\�硔��Ͼ��3�Ow"���z�K��Dq1�@�r�=	�b���Sb����芁Sb���sWl��-1�5��qy���bธ�rbl��m1�9r�iAz�� �x����FsQ&�?����mI��9�8t�G�L���Isi��*`�'9I4���we>�I2�dK�.��TMۜ�o���H7�-^��x��[�F��٘�b�R�ɦ^�+w!��{���p���)[n��ə�|'6RJt�6�?���H)<)��7�NЫH�Lt��mq
��B�:�G�;ŧ�o�d��[�Pߪ��N��"��D���D�����b�����H6ͲӖ��9�/ߛ�d��O��|�|J�)dN���&�xg3l���҅K����i�|n���|��b���ƛl)�nNH��I�U��W��H`�4J�ylE��d  �|���[��������Y���{c�ˮ��{�Y�������ȿu��w�#�OF/����\�=\
>�vi6*&o���f}n�997ǜ�[b��P�2/�2��ܚ��ܕ�6sؼ#��$?nNȦ���,*GIz4���I���%���}�_�u�8���(��L�i�����=e-���ӗ�[T�U�K�t-�u�.�V�N�oL��?�ي�,��3����59�9$ǕoYh���%b�<`�c���Y���鏧�s�rh�.� ��t�-&�2�.�ū��N&V���wq0/{�y�n�49��E+�wŻ\���.Θ�<�s1�?b,�����&��e�g�w�����U|s'3��F�5�� �O ^�߰ ���qr�ߒ�G^�+ygz�x5%����^��*�C��&�,Z�7S��h	y��г���-�j��ɑ霖�n�|�P�+��֔�qD{BK�څZ��W/���;o��MZe���Z�[i�>Բ�8Z�ݴ"��v���X�fg![7��i�tt���{��oSCv���H�\�1�7���%X��e�&8%�g�9�����b��.b������7ŉ	`�/�,D6{�ĕvذ�𒁥�7��n�f{j�����7=Q'���k���.�����7�������ښx�99#��3�����ͷT���θ��7^2�%�%fW�/m����m�|U
N��9����Ū�&��qq�>;f�1�#����9-^��T7EHK��i.Ԥ1�N'��&bp8$�h#DrS�r���Q>�/}����N����Mv;s����VQ�9�7��Ȋ�xZF�����.n>�[��EF/��GG;&{��5�4G���_�~�*M-�F�FS��
�q7���N~;�L����8�fuZ��d�{�:W2��.�ř��q���Z�n�ع�҉(a{11�|��0��J�Y07/���"|�\=���l��5��\Cxr�d 7�c�vew�4i�xv��,�αɷ�����>�U�1��g͔�.��)�KL�D���"'�R=z��n=[P+n�oi�LH��Q��2�d������đ���>�}﷯�!>��߽|n�c�<�:����Jۏ^}��u�������'?rSpHֺȻ����Q*����lH%XU���[k($�s;�у�C��]�>͓܏��1��/�S���j��Sm��\�6ۖ��K�M�+��:5S�m��~w��>�n��m��%ţd1^L��x���vH��KD+�|J\��KI����z)�J�X'���?�j���?}a��:�E,��i]RZ���W�	{�{�}�d!���Ud+�h��OO\�gZ�d�(,��6���r~�K&�}�����?�:Λ���>��՛��������=��9����|x����x�0��\������?N�i��nq\��n��\����y���]���/9O:#N^��[��.8n�f��b���z������w5Y2�~j:��J̘Mac<U�F���1#3&�i�}��r�Ȭ�?�].��#}��̲�_8�(b��c�q�K.�Sv�q�>�ΰ�wr�0!Q5��Z%�v"�ݦ�}����^�8�ri«_1�wz fUy����䜡_�V/aj��1_����-evb����2�]B��N�J��~%jmz�� 8��i-)�j�+n���f&��[�=��v>��/mՉ��܍K����.��� �ѳ���/j3"��\ͽȁKʤ)gc����X��~/}Kxԟ�PBMf�P���Y�Dp?��44�����5�dS<�ɞi�A�ڄ>aH�%�H����pTxI�
���.�@M�_�߽cg{�=(�	_^U�r�od׬Z�U�D�ȉ猬��U��S�i������J��Qxƶ�B�7�zDA�tP3�m��.��jxl�􂄈��J�v��p��}��|�i= .=L�o�B��m�^�nu^2�AS�>���*�͘�d�Nb��G����l5Y����4�����=f�8m���A�t^ݛ�;N��%R�l������%�1_���Ԙ��3���mM������[���w���oN�����-/`ScF��}�_�4�����y�<��H�_�i�<�}�m�����E���z%"�+|iH��H�i$�4����b�Q/�i{���q<w4�e|����x��Cߕ7��T��43���cQk���s�N��^�~�b"G5'�rl�� ��%�81zQ-O�Y+�ZD��D�i�}��k�<|U�x�q`|ǆ�[���?����o\�qݮ��^�E_�wg��+���\~U�u7� ����ю5?����ۏN���+b�W����?ye�����ͱ����;�{d˵^���ߛf�5�|�;�+�N-�C35M�a����Az��W�~(��#� ��Z��B���*�:�h'��B(�u���Hᐁ��p)'��3�F��懚3p����0-0/��%v�s�V���	�K��J'�K/��ڑ��Qx�G4"+�G~���iu2��X;�q��|$�P)P`p�*�9ɐk�PyT�uh&gP`=��)���厩��f��Hc�T�	l��C���Hc�T`2�sX���,�%
�CN{��Q��C�����_��1���7I�b0吘���ZV~�V���:��`=����S�)0�0�
<Ly]���.I����\�)��ֺ�x�U`��-�v3�@�̽��FJ[��6��2����)m��18`{�+�g8�08���	�i��08���Y�Bq|.�2�<�<�������g�t*��6
��
,���e��/g0����88h&��� jD�(i5�E=�v�viI9���qʻ��)C��H���C�A4�r!HC����	-��Z(�mPR�z�q�q�A�ۡ�-Џ��B�]��v����?:��~&*���<FCz�\	��8��v�Q��r�PJk� ��9Q>t�yt-=�/$��k���'��Q�W���F���l�4���m�Y���`���\]�J��r����a���ڇFm�1)�;X,)��+�ʿ��
N΃�]�r �P�0��Z����_��y1�җp%��]l���\sbZ4��D��#υ��Ĩ��ǎ�r4��C���͞���qz��J���-��7)�s`� 7�����KY��O��^]l�5��J(���ֱ��YM�kē�A90� �
�Q���3	�W|0*�����k4��������򲖵U%.�V����ȇZ��ֲFig=�s���jg{�b���.���n�G�����[�A��S�K�]�+��L�<s��͠lh�3e_|]=_��_�R�S׺��3u�Ti����ѿJ��Й�sd�r��v�vƽ^��N���������Z�W��Y�0�w}�֣�n�J��Ť�����XP��:&�݌^�_S�T�q��ʊ~U~Y�e3{@)��Y>�����ȴ]��O��\��Z�����K�5�Q��}l��<w����������R��>�Ԩ\n�2��������V�̤��3����[Au���` FS��%KLHo=��e��y�+J��TC��k�Jekߧ�6y�!e���� ���>�\�(��l6V�A+���%~�:HL�w+r�������4�_ V<'�Gt�e
����?���X;��*�K�J���[S���1v�*]�~��������1���FY͇b$�j!y��������^�h�1��S�����ʊ����A��Se�_����,c��T����6��M��uTu;�#{�L���H�-'��0�c,��?�ɲ�`3P�׼�h� ���4�Žs�;R��$�T�4ɧX�2�� ��z�U�~q+��U�r`�Ij�]�I�-����[)��uK�{��h1�V�U�J*��zv�P��
(���,�hP�؊�d6i)�`�N��ȷ0]�I,OsU�_}Ѷ���@o���]�� (x�E9���<��0m(�W���F�beJ�\��p*U�lD��j��C�K��2軒�G��/fpM���
�e�G�g�g��ֳ���^���Y����a1��s	0
��3���x�?MJ]#J�2x&gU�x��Q3ɿrH�r���md��ZV��60����.c��Y�+U�fC�JyPp5�%Q�ճX��>����[��'����)q9�\-�ɫQ�r�l�hm����l_u%�� �*c3n�J�b&�2��t�c��P"�G�6�U���G�^���J�/��e�'�����_��ǥ������ΐT���;��/$�������z{fHe��R}�����>4���!��KCk�CۤھPO#m�,��wˠ�ݻ��]j����O�H������&�yR}���SZ�i�m����v�HK�tБ;����~���K���vw��%eD��A���-��!H�n���-=�~i�Σ�QZ���͗B!)�im��#�!u˥RGh�����N���vu�(��
vׇ�o���ܘ�
%�Tʮ�j�北氊�P� �fΌ�Ŭ��Qn t���`GhS��Ի��y�u�2���ථ��R��u0i�T߻��G��j����Iu��������d��f��-h��"m
n����)����J��/Կ�kpزv;�[`Ų2��������>(��:a����v��wo��:��`դ`O���v�
�ΐ$u�ޞ��RvW���}���%I^9:��� �eK���<��|FAv�2�Dy���v�n����
DeRAb`��0�[�@�:B[){�3�����f]�u��ݽl5�ʓ���ޞ���98�7/??�3c[�Ʈ�PGWpFo��|���5����I����� �vs��u�]�{c�x��rC/N����x:u�Q~Mفtzut�L��1!h��?�ȓ���~Yn����YSV�l�H�ka�P������yP��� �T:z۷l�����ɦ=N��Ԡ(��sE!��䕸(���k���HU�"U�z����Q���/�Aa]q:�<iSoG�:��C����:�趀��n��Z��	�0&>�
=��V�tQRY:��7N3"�u�n�'s�Ҿ���Q�i/(KFˆP��*b��2�����<Ũk{��b�9�#�7Et7�MʊR5��y�M٢����SA����]*���y�-H��W����������"P!e�5@>+OZYٸ�vE��e5�-R�b���E����ȓ�u�����^���[V��ʚ�e+**k�H��]M-��J؏�ic�DT��4�Ϊ��K![��rYecK��������:-����+�A��Ku+��j0|t[SY��F	Tjg��P&� #5,-[��U���g���ֵ�W.Y�(-�]V��E��lѲ�<L�|YYeu�TQV]�$�Z�B/�M�n�� +���ৼ����N������y0���hӕ��<�����2dq}-tO�	-jY'Ю& �BY-MY@���IZ*eˠ��8yx$��d竵h;6�Ya�5�g���A9�t��Dw7���;� w�����4�9�75߼��?{S��{�o��|���4߼���=�7�i�yO��{�o��|���4߼���=�׾��rg2	���X�_��QK{���S���n�����4~_�/�/��d�=����R�V���:���Cb:���\V�G�P$��ȯ~�L��ˣ��R���q����Qm�{����u�_:�堓�3�Kuಸ���n�8��kO(��M��߉�g�q/�=�@�����R�k A���� h��4V+A�� ����K�\��[,�⒠-�v��s��!D p@�Fu�Zk ��Z�GKz!\��3���9F�,����d�����խ,�we��V/�ӊJm��6�H.��HN���ԞY0DS���hY"���_���cȊ1r���@8�R���{3��x�9�a w�(�GͶ�2������G�\CN��
(�����@8�#o��W�Wt9Iy�B@8���!h�Ixބ������|!��� �#>� ��@,�����YL�yb����g���5�^#�i/��`�/_ܙ
�HQ {b�8���g9 Q^Xi��C�4� r�F3g��9GK����o{%�������@��W`�W��B�>Z�^�U4a�!�!��A,B���^��*�	�����4
Ì���E�D�[�+� �'�f��9��@~���@�����47*3B=�6"�"��P�!�؛awG�l���q>��j!��p-9B��v����!���(z�����uȿ����� J4�λ ������{!K#��wD#��D#��D#o�V�h��� ���� D#om#@������r�n�R��l.m.m.mC<�F�Oi��hn.p�>�/'�=t�C�x�a<�CW�k�P)���!J�C~<t�Va�ؔl�߉���CO�<��C�x(I��?N�G+Y`��2�� �dh+I���̧�N8�	���4MFNJ�鴽����y��}�����2<�ބ��=b�,t�,t`�x!�5�B�B����w��
q>���@�������!ԫ���F��W����g��T.���SE���rw��5צE�H1JL�m��l�ؼ�S�?>5#}���N��R�;F?Ս��r�%��4$� /΄t.`��ȥ�ir�'!-u5A3�7�}[h����\����	����(��x��(yr���������wCrPb�\s�O=�P����F�W�d��*��F���������r/��*\k���s�{��[�Rk6m��=H��`.��b�z�X�+��q�?O�[hj�9B��'�n!UH�uv����L:�N���x�!]<�{���x�H-Oc��"�1�e�`A��pWE����vT�V
�k��c��Ua�g۫PU��\_ո����B�e�#���ar�8F���8B�nL���� ��v�m)4;��Lܺйо�V���"Q���֭s
�����9�DjK���Ԗ��w��:�?�g�Ҥ�� � ���܂����q�����@b�����8S<$��d��d�Lhx4<�e2�L�����d*F22�fg�!��<�	8��'q=�p�O�8����4C����P\8��4M��+(7GQnf#qx�%�O�8擀�u
�+��"���Ҿ����6O �-|��N'�O6�H{��ożmk�;i�[<��p��B���"իi�|O�ZhlY�U����x�-{��O���XEu鬎vVD�ZR|��bZ���UL�*�c-�/ac!&�u�#:���|���%F�k[JzˢD�o���ΫS�ǲ}-a�gQ��VM/�^F�`O�*�qJ�����)�n�J�b�g�n؂���
�g >P4��2\�}_���@��D�*��P^�|U� @i�Rx�Zf4�#G��P8�r\����2�^A���oQR�'q�����A4�Ӫ	��F�q������ ����l�O�҄�Y�[H�Š��-�ɀʒ�2��� 떱Ӈ�?�}I�
endstream
endobj

13 0 obj
15512
endobj

14 0 obj
<</Type/FontDescriptor/FontName/BAAAAA+ArialMT
/Flags 4
/FontBBox[-664 -324 2000 1040]/ItalicAngle 0
/Ascent 905
/Descent -211
/CapHeight 1039
/StemV 80
/FontFile2 12 0 R
>>
endobj

15 0 obj
<</Length 326/Filter/FlateDecode>>
stream
x�]��n�0E�|���"�FBH)	�>T� ��"c����I[�Йǵ�fVͱ1���I���~0��<ݜq��`=���_��B�m�y��1�TA��k��V�9��A��4��\��j}�ެ���"��,��ޟ��ٗn��T�F��[/�k8�DL�d+j�0�N����"�JQ�u���jqK�>;�[�o��]Zz���r��9%�#��3�'mΜ!?2����8ϑ���rE�Q��\#��I[3�71�7���#2��$2�Obd��R?���^��s�/���������~�"��9�z���`����ɢ��oZ���
endstream
endobj

16 0 obj
<</Type/Font/Subtype/TrueType/BaseFont/BAAAAA+ArialMT
/FirstChar 0
/LastChar 23
/Widths[750 610 666 666 277 666 722 610 277 556 722 277 556 556 222 556
500 833 556 556 722 556 277 556 ]
/FontDescriptor 14 0 R
/ToUnicode 15 0 R
>>
endobj

17 0 obj
<</Length 18 0 R/Filter/FlateDecode/Length1 21648>>
stream
x��|\Tי�s�3���ʇ�sagD��aA �
6`���f�j��I0�n�&M��ik�ִ �h��f��ݮ�6�H��fk�釭M������s��aL��������{��9�9����<�{�:���}�DH&W�.op�A���_�XJ�����?r�@d����������ȸ�o`_��ڷ>Mdq��}ޞ�V�!�_
������gB ���]�w0_��ѷ�����c�'��~8x�����W��|����wЇ=Ee�@(�C�Q"O��|�W�A�'�(�8����y_����c�J=YQ���B���(Q^���b�I���r*���";�OG)�.���,��������t���9��}��Q=Fvf%��)��Az�n�!z�.P>��K,r<�4Z�5�:�+z
\	TI_��l��P����|(z��)?���O��<��r��T�?i.-�����B;��+�4���Qv�5eS'TJ���NZO'�G��&�g�i�I��/�tv6z>�+����I��`����ɕ�c�R}����ы,�-�]�%ъ��>J�I�;�	v8��:�^z��1]�7X"[�>�N����᧰����f���#z���t�-g˥t)�J���!:���<�c��,��|�P<Y���U4JK��oB��<� ��ae�6��s<졇�y��x	q���zY���?�5�X��GVZC7�6
��K_��>Kߢ?���xp�S�m��p9�I�6�*`{#�[ � fi�&p�^�e*�X�X3�c���l���^��R��[����'�\Ye0D�AR-�^m�~��G�O���������X!<�1ƿ)���p}Q:'�$�!R�>>ya�oGGȄ,ۀ8�W�?�4�P�v��%,?,=)ϑ-�M^)��V�]�K�O�g�_�!��3C��k8a�NN� Z��]�����Ji5�ٴ�q�-t��'�/��ct~����G��f�X6l�C�.d���d��o�o�����M~I9��UR�T)UK}���~,�*/�����\G��R%j(�Uc8hx��=S�����/W.�����w^������򛓿�n���v*�e��NX� r�8�� ���`�����5&12>�ِN�Z9��jqmb7�ڌk+ۆ�˺X?��� �(��}���>-��������)\_g�q���g��~�^��Ē�l�KK�"i-<��6H�R3�>)�+(I{0C�J��)��r�l�e��[~P��������")N�H)S�(}���9��O��V���o8bxָ�Xj�l�a���	��+&����e���)g�n�O���-��x���K�.2��N�3J���	���첬����/�~Q���"��ˑ��ur/�CQvBzYz]��2��J�f��߳�K�R2�}���|�vëD�Oh�t+;+}[�]�=���p��7�~@�rAJ��X�wJ`пJ~� �)���ɏ���a���.�T~A9B��6�O�2�����F%W��������[L��n
�O��=�~�&����GY���يHf�G���l���@��F�'�gM�ei����yy%c�%��nf2+F��>�4�p��{���Y	e���_�|��؆�"����LŴ]����xW}�J�4r�.*�>C�D�����J4�vPK�n����H�r�v@�_���~�=�e*V�Y�W8�Ń����A\=����Ɠ�R#K'R��#��Ӈp���P��F+NX�bgލM֐���{L�[a�X�MJv���;�gT=����}�*1w��ۣ�#�p�&꣖�c��D�h�ih��J)���طp�;;�}��~����2�7���o0<M#�O�w�G����#9�PNы��~����gi�d�4���8��Ӎ�G�V�@�����q�{�Zl8��=��JŰ���X�7��?���]�[]�7|�l���kV�ZY��dyqѲB�ciA��<{�-'[�.�Z�pAfFzڼԔ���9�Ą�8�Ѡ�#��VݩF�:#J������m^ �3����<�S���9]�콊ӥq��8�E-��B�걩��W��	���6��V����%o�a�ggc����R#�S�D���x:� n41��V�K(t�hB"�D@�t[p���� �{֍Jg�Q��*O$�V�-��v��'�tc��javv{�3�*�m]�UD���*����2bjT?����γ#�LX��ӑ�c�������\�\�VE�o��1݅�ʶ;gR�#��ʻ##w��c7�ͤf�2"���s���A�ZT��ho��;�P�~p�4�|6�t�P#�
[�ȎNL̂�5��[��u*z�xԑ�6[v�|���[�ht�4��t���)��Q�\-��s�u �<�M�$�9T�<W�-��""j�
K�l�i�|kh�{��ig��|�#�#�u�[����n��#o��v�w�1^c�[� �,�J4�cp��,]��T���7���B�	)bZT45!���uE~v6�ރ.�B'r��6��R��1r9�#R'���Q�o�1���N��I�2?�7�/ْ���_ai�C�i��[ݍ��T�H�ۺ�Y=��f��CL# �ŎH�ڐz���8��j���Y��#��m�B�]�������iJ2�%qY��(�g���VG,�5Zݞ���W��^�D3=L�)��1��~V�yI#2V��m##	�h�جFF�mj�H�w"z�˦Zl#��6�m$��M�D������{��D?[�Ԗ�b���q���j��vʂ�ѻZ��$&UvV����vJ%r	�ı�;*���ê����S.�����wO0���Q����,��<�ȅö{B�(��\��;�q���q�X8�4a�'A�>|��lm��<bE�"%�w>�D2��7�J�i���6Ig�ȠLH�xR�N2ʌ3΀.��
(��d���Ͳw�,��mz���[��Z^�=7{�[��U>{�e��quN_�B��O��2:3�e\�P(Õ!���.�q����p���l�=�_(��qj���Ò����qI����?��֕2gN�k�����ɇ��%+ə駥\v���펲M�K-���)k�ܵ�ƥ+��c9������s祥���^y��rn钼<[��2ۘ�ZvӤԹ&-�d_`�P����Z�X�ۥ��7K?�o���ʟH���|\��]5e$�M�X���L^%/NK+0��jM_6]��mqLߖ�3.<7��P���<8�����<gx.��3^L1����V���,K�4,�������a�OO�H�*�ܐyw�!Ք�)I�2�2�f9S2q�0�)U1O���x׼���,~B^�J��dG3�Ȕ2O�+�{Ǚ��x���2��?S;R��S��	fr��l]@�K=�ʝ�1UR3�fo!s���ׁǃ��!���K@�gZO�Q��!�t��R�e��7�oz}�%�%���;�w����{��3���ٙ�s�m���87%}�����k%���䭙�f��>��N���o����b�{h;f��p����+�V�b��&۪U+J��F�d�.Y�j�|�������y��s�;��⍏�u��Z��&߶�
��/�����S�y�p_�NN^^cY^�[���[0�%��%D/�%�����u�%�u�{��r�s�`M�����\��?'�������n^���S���=�����ߗ�&����ڸ�	v�x~��&������	���l����	v�d��QT�5�*�-���Y?ͣx问�&́tX�fr<�Ē&�a�J��J����0���+�W);Vz�T*�=�_w��I�R3W�f�٫S$f���ݯ��"V4�_r\*���R�ڢKˋ+��V-+Z����s�mٹ��l�h����KP�X�R��'�N\������՜�E����'��Xz>b��n�#�O�H�41Y�9y+K*-=mE	n�����g��Ϭ���Ǿ������������Eٙ�~8ݾ��������h�m���W6������;�������XՒ,g��ܘxd��nMV�{q>�ط���g�ܝՑ\�F\f�x���/���~�����'�')ƙ�'=�u����l\��/`®��3�z\_e��>&���$�+���hL)U~<Ǯ�~�wgN^�IZ��,F͑��LmR�+�9��ʐ��a#�H/谉�Ho�p�:O��a�9Oɉ���skt�Qr�f�Ȕң�29Sv��t�@I)�谑榌鰉֧���QFʤ�Sej����Jm�d��Е��;�Y2�"`#�/�����p��sC/(�a�pQ�#���:�.��#��~�È��u1�J�a�0k�#�Y_�a�0�Fop��q@���6�=N��<G��	��ms<)�T�)�g<O�h��9�&��)�^�B��Lp�q.�U�y����/�K��<������~%i�^_�C�e<��P1-�R@��O>��(@�(a�GA��Do0�����2P�4�K�f��0>L!����{��i�U�^�>�L��>�1=�����!G�� d��p7`<�clL�:e}1�'�9�[�U�m����� 2�i�λ�~`9u6��|�q�?�Ӟ^�*���c�"�}��tOU�e�n�/��B�^��ap��ȩ���6���ŸA��b�Op�ht�H��Z�-����/85��~pzV�12�(��%ƨԠ���]"�|~�`뀰��|Y�ߌV���o��º�TL
�)[D�BS����k0�ӣ�1�#���o���N�3����="��ҝb.{�Gk�o�n��uR%8��sq�+��_ϪB�1�����4�C�3.���-�?����Gd�������E����}"?�|
O��^!1,"��A1/�@�Ҳ�K��峇6C�{F��(A�=��-$��|����J��^��+|@�eM+��g6�����������n]��=��wy��'��+8sս�]����Gi暎���ڰ��{*S������v����KX���������A��y��S-��YQ����^k^i0�M���ʭ�3�����w���#3%�[Wܚa�����:E����g�ݻ��;g�8m���p�W$(˄��b/�����}�G�V���j�.�xŻ/�Mۉ4�c��-g�_y����Q��fM��ഈ���'�������;_c���gll����Ah�^�嗖1>]_���A}�8��C�����|���9��:���b|P?/4H�λ��l���}FL�������W��c�����'ՠ�u��;{H�n�{ϯ8f�i`�fĈϲf�֚���]�/�Ÿ��W9�ګb��z�8��W��k�.pz�O���:��Zz����w!m�B��:-4���-gh�s�~��a�>�!�R�l���ٹ��GuZC�˙��윞��^�]��y����.uP����4@ڝ�t\v��{�I~�=Y��{���kݻvs/���s�{��(vnL�(v6M�i�2{TH��|u�_���ǬME ��o��p��3��3Ϻ�=q�F�Fo+�8�i3([Ы�
�%�h��KČmgR�6��N�ь��v��U�*��W���c=�&tx �Ep6ٛ��G�����J`6���b7��5`��4S��������Sζ�Vh�Y�	�f���t��k�<n?�_-��);�uK�"F\2�Y�߇6�f�M�k���g���C5�/a׼L�U���٢S�q��qM{�1��Lǯm,��7��*N�F������y��qo�Eo�+m�*�7<�<U�7�l��]��5[�gH����>ͥ����J�F��f�R�Z�\q�S��f���Z��L�.��e*C�E�j�ǲS��8�M�ۙ�ĲZ}�5�I��7�3���EL�]-S��K�/�%��K��~��)0�����P00����T���������f_�7��׳L5�k|]C��jc�7����{����@��߭v������/^���f�Sm����`w�{'���j�pO�kj���ԁ�rzCj��k���Pu��	@�
u����z�|��`�oHs?j[�z�o0�[��|>շ������Q4���u���A�����B�Z��|!�Z����;���P,.�"�:]����
pK
�b��
q%���Y-H�BS˦֫��3����vy�v�������"L�ĜTy������^8��-a���o��r�������ޡ�`X]�vEI{`X��ݧ#Na>#�P�!5����Ʈ}"Ξ��n>�	z��êP�����1��{`��@8���CA̲���(?����T5�<08�O��hS7S�`���&i3�}��C�A��çd����%���#8�֞�����w�R��LE��� T���=�=<������Ȝ`N�s����SЩvyC0(08��������늊|����w����wY`������١'w�S��~$�s1�^��ZE��s�s��X��p�o�o +L�t�z��b�{M|B"�/Ƈq}C^�ǩ�a�!����C}�rp�8P]Xw�<,^�gpο�n�7
t��<z�ûx�����M>�8�_�E�4~X ,��A�_��k�{��~���UN=���1���沆�m���s��@����>��0
�;�����0�!������0$��֣tMS� �R[z��{����G���C�0F_�l���p,Ŧ39���k],ͽ]�=��?6#�6�E|5�sE'�����7k�zg�:�a�
�1IX�ڊ~�h��ƣ�4V�nu7{�����qKm��J]�nA�S�Z�ZӸ�UG����]m�V��j]mC�S��55{ZZ��f�vSS}��چ���U��
�kh�1S�����*W�����pa�<͕5�+j�k[۝jumk�Y�n����Z[�=�Ym�������*�m�m�n��&OC�2hN�lAGm�q��U�Ͱ�Y�W����\���U�i��� Y�e�z��
NUֻk79�*�&���)͂M�nk�G��ύ����܍�Ɔ�ft��uj����Su7׶��T77B<'F4
!��Ѥ�P��f,����3mK��]Y-|�L�e��	�'"�x�}̌g�x6��x.��b��h�˟�G��Ϡ��Oˏ�_~g�=�\ot�����F��]ot�����F��]ot�����F��]ot�����F���?��h�w2ӰW�ע�<����3��ўĮ-s@����+���J��A� 굳4B�{I��a������~a�$���smX���~6�]��ƾ%�A�*e�U��|���^3fY'�ߍ�K�����E�MG�W�<�B`,��Q���(��Y��q���5�ֱL�c�%�8al����_��>g��X�BAyi��BV�р�%��	�K�I~I>��(1j<Y�e�&��#+�A�\���s�J���������e>�1���'�����Oꔓ�s斐;$�K�΢~��e����(
%����4r�|B>;����.B	�BQٯ ����c����{��h>ڃ�D�%��~��hF��G����r�gu��觡���> �B�����b�?�����b\Xo�ɡ��V�{1�*J1��>@�!t��LA�����im	�]Z�p�:�mst�xzf�1��V��VD�VD�VR@�%�s��S(��[�sxnAT������GmAQQd�=��s|�Y���c���=y/�X ��w��[�d}�k]%�O˽�K���*94݋O���v��&s^�����8�7� Kk���=GC�h�\�R�*E��-���hW��X�K����~�R\�R��%�GH�����P`�(c�;���eK�_�o�7���!Y��Er��(wȆ���1Ӻ��T��VN<�I<��|�!b<k|�x�x�hP��F����i������`�Dْ�&'��V;�C��AmA	�FQ��U�C(����C��9�	=��/�5���d�%�l2�J&JJ'JP��(�1��2��,u���P_��F����3��y�
,��VQ�$�������A���N��_<1�������K��H;V�0WY��ĕ�*%%���a���8�l{ ?p\i�5���+�r{y~�q��Vd/�/:�XmV�5�z\9T�D���s�JG}�~��S7>�(.m���'�2��Nv����;����G�Ɋ��%��HO��b#.B)GiD�@1`�W���ڪ�8���q�ӥYt�?>�nE�{����(2d?��[����ߨ�x+��Y����6�����t�QtNފ#b+��ڊDyE����*o����q�q��2/�o��4�B)s�,n���L0��D�Q�-�rQ��l4�������o4/ ��7��D��Jt��t������)���|Qy�~+�Q;]��oe���m�c��������d�q�����<Q'��/ꍢ�s%Z�߱��Zͫ�f��a�N�^,ꅼf�=�\�L�O��p�b��XY�uB"Ѱ�X���X�4A�_ce��>��b�`co��^����Y�����?�Z:��2�>��P����X�m����Y��@9q��aj㎲Z���>�1g�~n̹Z?KN���1�E`?5��'ǜh�ٹ�;�ʖZ�sY�J������^�X�h7h�=cN>��+�`�c��h�p+�a6j�c6�dل�EdF/$�h�da��rD7f�R�O�/Z�\�4w��`�cG��|�mA�?X��	�N�p�Y�9'��)�ڞ�~;w�m��uNāp�9!���Q9^�=e}��g��MP��@�T-+�~ζ����1�m�g��o��y���섵�>�@v�A�+���6d]��	V;~º<w��R'��.��<�0e����J2�a��6u���n4�7�0�TS�i�i^\J�%nN\R\B\\�1N���(n�D���z8�h�I�"`��kI����$��H�\'յT�HJյVDV;�&L���G]$��m��}���t���6$(Gݱ��E�S�X��.��-w�����"g���K���?n�1�*2(mOyFy�s�VW]���k��'�1�����-��H	�Y�u��o���vKO�))ț��S�fi������U�Sl�#�Fe��l���(���z��4��T���hLϲZ΄�yV0�i�r���x6i1�
Y��bΆ|Є%��D,YKN"!lg����s���v0��W�i�ͮ��Nv���څƦy�5d��#Ł������ٸ��=��/�t�<>����=��]�:��s�O��uvu������櫊�ت�Qo�5�ݜ�U�R���m�������}����u�t�=��r�5����*��G�A���G��:����z����U�\���F㨢��&���:f�W�Y�7�ű>;�#O+�c+��I�UD�(�T�.tsV''��sG'e|d}����1�dz������WM��B�������ƪ�n��T�?R)�D\�U��g������e9Sv�L
��/;Tv��2��p;�)gr��H9���9�r��<�c䄛ڞr���C�<�tba|<UB�0Z����0�&DPB��9��m�����Q���PV����Q��(BQ�vԟB�"�8�ȅr�'�_�5�;���!���,Y3��۫�-۴�Ӡ�e��c�+�ɸ�ft�wQ~����B1�%r�>��m{�B�	�0�B�0s `<���A�����ىO,4L&�6ć�6��Kq�/���
endstream
endobj

18 0 obj
9824
endobj

19 0 obj
<</Type/FontDescriptor/FontName/CAAAAA+TimesNewRomanPSMT
/Flags 6
/FontBBox[-568 -306 2045 1040]/ItalicAngle 0
/Ascent 891
/Descent -216
/CapHeight 1039
/StemV 80
/FontFile2 17 0 R
>>
endobj

20 0 obj
<</Length 237/Filter/FlateDecode>>
stream
x�]PAj�0��:&� Y��JB����n KkWPKb-���䴅$f��avť�v�%������EX� ��R�:���f֑	��ے`�����7Җ�?<�0������O��q��k�_0�O\���Fʹ���g�u�,�.m'���o�*�ګ�`a�� j?k�lys������w�0�O�4YѤ�J��U�u�q�c��y�u�{8sr^��17+"�-�)5sA����1��*���tJ
endstream
endobj

21 0 obj
<</Type/Font/Subtype/TrueType/BaseFont/CAAAAA+TimesNewRomanPSMT
/FirstChar 0
/LastChar 4
/Widths[777 250 500 500 500 ]
/FontDescriptor 19 0 R
/ToUnicode 20 0 R
>>
endobj

22 0 obj
<</F1 16 0 R/F2 21 0 R
>>
endobj

23 0 obj
<</Font 22 0 R
/ProcSet[/PDF/Text]
>>
endobj

1 0 obj
<</Type/Page/Parent 11 0 R/Resources 23 0 R/MediaBox[0 0 612 792]/Annots[
10 0 R ]
/Group<</S/Transparency/CS/DeviceRGB/I true>>/Contents 2 0 R>>
endobj

4 0 obj
<</Type/Page/Parent 11 0 R/Resources 23 0 R/MediaBox[0 0 612 792]/Group<</S/Transparency/CS/DeviceRGB/I true>>/Contents 5 0 R>>
endobj

7 0 obj
<</Type/Page/Parent 11 0 R/Resources 23 0 R/MediaBox[0 0 612 792]/Group<</S/Transparency/CS/DeviceRGB/I true>>/Contents 8 0 R>>
endobj

11 0 obj
<</Type/Pages
/Resources 23 0 R
/MediaBox[ 0 0 612 792 ]
/Kids[ 1 0 R 4 0 R 7 0 R ]
/Count 3>>
endobj

10 0 obj
<</Type/Annot/Subtype/Link/Border[0 0 0]/Rect[56 356.7 148.2 370.5]/A<</Type/Action/S/URI/URI(http://www.google.com/)>>
>>
endobj

24 0 obj
<</Type/Catalog/Pages 11 0 R
/OpenAction[1 0 R /XYZ null null 0]
/Lang(en-US)
>>
endobj

25 0 obj
<</Author<FEFF004D00610072007300680061006C006C00200047007200650065006E0062006C006100740074>
/Creator<FEFF005700720069007400650072>
/Producer<FEFF004F00700065006E004F0066006600690063006500200034002E0030002E0031>
/CreationDate(D:20151014152341-04'00')>>
endobj

xref
0 26
0000000000 65535 f 
0000028317 00000 n 
0000000019 00000 n 
0000000586 00000 n 
0000028479 00000 n 
0000000606 00000 n 
0000000854 00000 n 
0000028623 00000 n 
0000000874 00000 n 
0000001122 00000 n 
0000028879 00000 n 
0000028767 00000 n 
0000001142 00000 n 
0000016741 00000 n 
0000016764 00000 n 
0000016955 00000 n 
0000017351 00000 n 
0000017598 00000 n 
0000027509 00000 n 
0000027531 00000 n 
0000027732 00000 n 
0000028039 00000 n 
0000028219 00000 n 
0000028262 00000 n 
0000029019 00000 n 
0000029117 00000 n 
trailer
<</Size 26/Root 24 0 R
/Info 25 0 R
/ID [ <FAEEF33AED68F85DC67884FA0044EE41>
<FAEEF33AED68F85DC67884FA0044EE41> ]
/DocChecksum /16478DC25D9E74C6FCF765844F1EBD78
>>
startxref
29386
%%EOF
  [      �� ���    0 	        �PNG

   IHDR         (-S   tEXtSoftware Adobe ImageReadyq�e<   �PLTE���}}}���~~~���2Q�������������������d�c����G^����w��@f�Zz�g����^�룹����RW|Ec����q���훲ה�����b�����b��������z��l��c�9Y�������E`�b����d�2Q����������(x����7o�De� s�o��l�����c���ㄴ����������i��3Q�������Dg�1O�?Psh��d�Eb�i��k�������   QtRNS�������������������������������������������������������������������������������� h��   �IDATx�d���@E��!��$��������R���ŭ�i���%�����>g����T5�^dIjȵ�;��A�/�m�Z�u&��΃�#Į3q#�	�Q*�*����� �#�����	U� ǋ`w!�n�
��T�盼�9"h��̈́[�|�` �;��/��    IEND�B`� �       �� ���    0 	        �PNG

   IHDR           D���   tEXtSoftware Adobe ImageReadyq�e<   PLTE���������  �   �����   tRNS����� ����   FIDATx�b`% *`�X���f< �&&"[�H<��*`�	F�* C�4I(� s7@� ��'�*    IEND�B`��      �� ��     	        (       @                                   �  �   �� �   � � ��  ��� ���   �  �   �� �   � � ��  ��� ����������������                wwwwwwwwwwwwwwwpx��������������px�������������px�������������px�������������px�������������px�������������px�������������px�������������px�������������px�������������px�������������px�������������px�������������px�������������px�������������px�������������px�������������px�������������px�������������pxwwwwwwwwwwwwwxpx��������������pxDDDDDDDDD@    pxDDDDDDDDDH���pxDDDDDDDDDH���pxDDDDDDDDDDDDDDpx��������������pwwwwwwwwwwwwwwwp��������������������������������                                                                                                                                (      �� ��     	        (                                          �  �   �� �   � � ��  ��� ���   �  �   �� �   � � ��  ��� ��������        wwwwwwwpx������px������px������px������px������px������px������pxwwwwwwpxDDD���pxDDDDDDpx������pwwwwwwww��������                                                                �      �� ��     	        (   0   `                             qj� {r�     �R' �Q' �P' �H# �S$ �S% �R& �S& �R& �R' �hC �W! �V" �V" �U# �U$ �iP �Z �Z �Y �X  �X  �^ �] �] �[ �\ �a �` �` �_ �g �g �d �c �l
 �k �i �i �h �i �e) ʌP �b  �b �b �t �s �_ �[ �[ �c �r �v �p �b �q �o �p �x
 �n	 �h	 �w �o �t �y" �}' ߋ, Ȃ3 �E ֎@ ��U ��| ��� �s  �q  �f  �c  �b  �c  �t �u �t �r �j �e �c �c �] �[ �\ �u �v �t �u �t �e �] �\ �v �u �v �u �q �n �o �\ �v �w �u �v �u �w �v �w �w �v �w �x	 �x
 �y �z �z �z �{ �y �w ݂ �t �t �' �( �, �, �- �- �. �0 �0 �0 �0 �1 �3 ی1 �6 �7 �8 �8 �8 �: �= �> �= �@ �? �B �D �E �I �I �I �S �^ ��� ��� ��� ��� ��� ��� ��� ��� ��� ��� ��� ��� Fp� cq� ��� sss ppp iii aaa ``` ___ ]]] [[[ YYY XXX                                                                                                                                                                                                                                                                     ����������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������	��������������������������������������������
������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������!�� ��������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������%��������������������������������������������%��$��������������������������������������������$��"��������������������������������������������#��"��������������������������������������������#��"��������������������������������������������#��*��������������������������������������������+��(��������������������������������������������)��'��������������������������������������������'��&��������������������������������������������&��?��������������������������������������������?��<��������������������������������������������=��9��������������������������������������������;��7��������������������������������������������A��63[4]5mm]5\]m]mm5\mm5555555\\\5\\\5m\55\\5ed:���cOXY/P.Z0.0.QR00/ZPP0000000/0PPZR.BI@/DE0, �C��WkV21TSav^8{|}>qooggggggg1`_fhsnHK�{JLp��G���l�����������������������������������������-F�j���Nw~ytMMMMMMUbbrrrrrxxxxxxxxrriUMMMMMMMMMUuzt���������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������  ������  ������  ������  �                                                                                                                                                                                                                                                                         �      ������  ������  ������  ������  ������  �      �� ��     	        (       @                             ~r�     YRO �M" �M" �M" �O$ �S( �S) xH0 ~L3 wG0 wH0 rE. xI1 �YB \TP XRO �K �N! �O" �N" �N" �O$ xI0 pE. ZSO �h: �lA �j@ Ȕs Ǘz �B  �@  �i7 ̖q ʕr YSO b_] �F  �E  �C  �D  �E  �C  �n5 �l6 �f> Ηn ɗs [TO �L  �I  �J  �I  �s- �r. �p0 �o1 לj ��_ ՛k Қl Йm ZTO �Y  �K  �I �w* �v, ۞h ٝi �i  �Y  �S  �{$ �z& �x' ߢe ݡf �m  �k  �l  �m  �n  �o  �n  �j  �m  �k  �q �} �$ ކ* ݉* �7 �? ��D Ջ; �@ �Q �b �c �b �b �o  �f  �q �r �x � � � �{ �z �{ �z �u ۀ ܀ ܀ ܁ ܁ ܂ ܃ ܂ ݃ ݄ ܄ ݄ ݅ �! ݆ �$ ݆! �& �' �* �+ �- ۉ* �/ �/ �3 �3 ��5 �6 �5 �7 �7 �8 �; �= �? ԍ7 ��V �p ��� ^][ �Ҫ �Ѵ �϶ �ϴ �ϵ �ͳ �ѷ �ҹ �ӹ �ҹ �Ӹ �ӹ �ս ��� ��� ��� ��� ��� ��� ��� ��� ��� .j� ��� ��� ttt ```                                                                                                                                                                                                                                                                                         ����������������������������������������������������������������������������������������������������������������������������������		
&�������������������������������1������������������������������������������������������������"���������������������������$��.���������������������������#%��-���������������������������0%��:���������������������������?%��9���������������������������>%��8���������������������������=%��7���������������������������;��E���������������������������G@��D���������������������������F@��M���������������������������O@��L���������������������������N2��K���������������������������h2��\���������������������������g2��]���������������������������f2��[�������������������������������I3')+*+)))*))()*+++,6J!54 CBA���jYPQTVTSkllZTTXRTUiHceWda/� i���u����`�������������������_<bm����t^��}zy|yx~���{|yvrrwsqpon������������������������������������������������������������������������������������������������������������������������������������������������   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �  �  ����������������h      �� ��     	        (                                        |WR ��� �Q3 �O1 ��b sP? �Q2 �Q2 �Y9 �^G ײ� �`E ۹� �cE �bE ݹ� ��� �o7 �f@ �gD �eD 㼜 ໝ �Ü 徚 �b �c �c �d �c �d �d �s  �x( ·> �zZ 翘 ��� �g ഄ ��x �$ �& �* �+ �+ �, �- �- �/ �0 �4 �6 ��I ��� ��� ��� ��� �ڽ ��� ��� ��� ��� ��� ��� ��� ��� ��� ��� ��� ��� ��� ��� ��� ��� ���  ~~~ }}}                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 PPPPPPPPPPPPPPPPPKMNNNNNNNNNNOLO	O&:
OJHHGGGGGGGGHI
OJEEEEEEEEEEFCOJEEEEEEEEEEFCOJEEEEEEEEEEFDOJEFEEEEEEEEEBO%JEEEEEEEEEFFBOJJIIIIJIIIIJJO(@>=77A779?<8;$O' "!)O6530./21+*-,4#4PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP����� ��  ��  ��  ��  ��  ��  �  ��  ��  ��  ��  �� ����������%      �� ��     	        (   0   `                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��H#��P'��Q'��Q'��Q'��Q'�   �   �Q&ݤR&��R&��R'��R&��R&��R&��R&��R&��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��R'�   �   �R&����������������������������������������������������������������������������������������������������������������������������������������������������������������������������������S&�   �   �S%����������������������������������������������������������������������������������������������������������������������������������������������������������������������������������S$�   �   �U$����������������������������������������������������������������������������������������������������������������������������������������������������������������������������������U#�   �   �V"����������������������������������������������������������������������������������������������������������������������������������������������������������������������������������V"�   �   �W!����������������������������������������������������������������������������������������������������������������������������������������������������������������������������������X �   �   �Y����������������������������������������������������������������������������������������������������������������������������������������������������������������������������������X �   �   �Z����������������������������������������������������������������������������������������������������������������������������������������������������������������������������������Z�   �   �\����������������������������������������������������������������������������������������������������������������������������������������������������������������������������������[�   �   �]����������������������������������������������������������������������������������������������������������������������������������������������������������������������������������]�   �   �^����������������������������������������������������������������������������������������������������������������������������������������������������������������������������������_�   �   �`����������������������������������������������������������������������������������������������������������������������������������������������������������������������������������`�   �   �a����������������������������������������������������������������������������������������������������������������������������������������������������������������������������������a�   �   �a����������������������������������������������������������������������������������������������������������������������������������������������������������������������������������a�   �   �a����������������������������������������������������������������������������������������������������������������������������������������������������������������������������������a�   �   �a����������������������������������������������������������������������������������������������������������������������������������������������������������������������������������a�   �   �a����������������������������������������������������������������������������������������������������������������������������������������������������������������������������������a�   �   �a����������������������������������������������������������������������������������������������������������������������������������������������������������������������������������a�   �   �a����������������������������������������������������������������������������������������������������������������������������������������������������������������������������������a�   �   �c����������������������������������������������������������������������������������������������������������������������������������������������������������������������������������c�   �   �d����������������������������������������������������������������������������������������������������������������������������������������������������������������������������������d�   �   �g����������������������������������������������������������������������������������������������������������������������������������������������������������������������������������g�   �   �g����������������������������������������������������������������������������������������������������������������������������������������������������������������������������������g�   �   �g����������������������������������������������������������������������������������������������������������������������������������������������������������������������������������g�   �   �h����������������������������������������������������������������������������������������������������������������������������������������������������������������������������������i��   �i����������������������������������������������������������������������������������������������������������������������������������������������������������������������������������i��   !�k����������������������������������������������������������������������������������������������������������������������������������������������������������������������������������k��   "�l
����������������������������������������������������������������������������������������������������������������������������������������������������������������������������������l
��   "�n	����������������������������������������������������������������������������������������������������������������������������������������������������������������������������������n	��   "�o����������������������������������������������������������������������������������������������������������������������������������������������������������������������������������p��   "�p����������������������������������������������������������������������������������������������������������������������������������������������������������������������������������q��   !�r����������������������������������������������������������������������������������������������������������������������������������������������������������������������������������w��   �c��_��]��[��\��[��\��\��\��[��[��\��\��\��\��\��[��[��\��\��[��[��[��[��[��[��[��[��[��[��[��[��[��[��[��\��[��[��[��[��[��[��\��]��b��t��   �e��f ��e��c��b��c ��b ��c��b��b ��b��b ��b ��c ��b��b��b��c��c ��c ��b��b��b��b��b��b��b��b��b��c ��c ��c��c ��b ��o�֎@��h	��b��y"��}'��b��e)�qj���iP��t��t��   �j��n��r��s��t��u��t��u��w��u��v��y��{��z��{��z��x
��v��w��w��u��u��u��u��u��u��u��t��t��v��v��v��w��v��E���|�݂��y���U������u�{r��Fp��cq��Ȃ3��w�   �   �o��y��S��^��E��D��I��I��D��:��B��I��6��3��8��?��@��=��>��>��=��=��=��=��=��=��=��8��,��0��0��-��.��(��'��,��0��-��0��1��7��8�ʌP�ߋ,�ی1��q�   J   �w 1�q ��v��z��x	��v��s ��s ��s ��s ��s ��s ��t��t��t��u��u��u��u��u��w��w��w��w��w��w��w��w��u��u��u��t��s ��s ��s ��s ��s ��s ��s ��s ��s ��t��w��x
��v��` W                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ������  ������  ������  �                                                                                                                                                                                                                                                                                                                             ������  ������  ������  ������  ������  �      �� ��     	        (       @                                                                                                                                                                                                                                                                                                                                                                                                     ^   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   i   �G ��>�:��9��8��8��8��9��:��:��:��:��:��:��:��:��:�:�:�:�:�:�:�:�:�:�:�:�:�i2�	�   ,�K��S(��O$��N!��N!��N!��N!��N"��M"��M"��M"��M"��M"��M"��M"��M"��M"��M"��M"��M"��M"��M"��M"��M"��N"��M"��M"��O$��S)��O"��   1�lA�����������������������������������������������������������������������������������������������������������������ɗs�#�   -�j@�����������������������������������������������������������������������������������������������������������������Ǘz�
�   +�h:�����������������������������������������������������������������������������������������������������������������Ȕs�	 �   +�i7�����������������������������������������������������������������������������������������������������������������ʕr�
 �   +�l6�����������������������������������������������������������������������������������������������������������������̖q�
 �   +�n5�����������������������������������������������������������������������������������������������������������������Ηn�
 �   +�o1�����������������������������������������������������������������������������������������������������������������Йm� �   +�p0�����������������������������������������������������������������������������������������������������������������Қl� �   *�r.�����������������������������������������������������������������������������������������������������������������՛k� �   #�r.�����������������������������������������������������������������������������������������������������������������՛k� �   "�s-�����������������������������������������������������������������������������������������������������������������לj� �   "�v,�����������������������������������������������������������������������������������������������������������������ٝi� �   "�w*�����������������������������������������������������������������������������������������������������������������۞h� �   "�x'�����������������������������������������������������������������������������������������������������������������ݡf� �   "�z&�����������������������������������������������������������������������������������������������������������������ߢe� �   "�{$������������������������������������������������������������������������������������������������������������������b� �   "�$������������������������������������������������������������������������������������������������������������������b� �   "ކ*������������������������������������������������������������������������������������������������������������������c� �   "�}������ս��ҹ��ҹ��ӹ��ӹ��ҹ��ӹ��ӹ��ӹ��ӹ��ҹ��ӹ��ҹ��ҹ��ҹ��ҹ��ҹ��ҹ��Ӹ��϶��ͳ��ѷ��ϵ��ϴ��Ѵ��Ҫ�����ԍ7��   "�Y ��L ��F ��C ��E ��D ��E ��C ��C ��C ��D ��C ��C ��E ��C ��C ��D ��E ��E ��E ��C ��I ��S ��@ ��J ��I ��B ��I��K ��Y ��   $�f ��k ��m ��k ��n ��n ��n ��m ��q��r��r��q��n ��n ��m ��m ��l ��n ��o ��o ��i ��@��b��j ��Q���D��f>�.j��~r���o ��   �n �ۉ*���V��=��;��?��7��3��?��/��/��8��7��5��6��6��-��&��*��'��!��+��3��$��3���5��7���_�Ջ;��x�h   �t b�x�܄�܀��}��{��z��z
��|��z	��y
��|��}��}������~��{��|��z	��y��s ��s ��y��t ��t ��{ ��} ��|��m �                                                                                                                                                                                                                                                                                                                                                                                                       ���������                                                                                                          ������������h      �� ��     	        (                                                                                      
      k   �   �   �   �   �   �   �   �   �   �   �   �   {   O�O&��F#�C!�C!�C!�C!�C!�C!�C!�C!�C!�C!�A �E$�R(�   pְ������������������������������������������������������rE+�   pٵ������������������������������������������������������qD)�   p۵������������������������������������������������������tF'�   p޷������������������������������������������������������wH'�   pḖ�����������������������������������������������������zI&�   p五�����������������������������������������������������}L%�   p滒������������������������������������������������������N%�   p���������������������������������������������������������M!�   pް}��������������������������������������������������ڽ��c>�   p�c��d��c��d��d��d��c��b��c��c��x(��s ��o7�|WR��zW�   R�y��*����������������������$��1�mp   	                                                                                                                                � :�  ��  ��  ��  ��  ��  ��  ��  ��  ��  ��  ��  ��  ����������v       �� ��x     0	                 �      (   00    �         �       h   00     �%          �        h     �      �� ��	     	        (       @                                   �  �   �� �   � � ��  ��� ���   �  �   �� �   � � ��  ��� ����������������                wwwwwwwwwwwwwwwpx��������������px�������������px�������������px�������������px�������������px�������������px�������������px�������������px�������������px�������������px�������������px�������������px�������������px�������������px�������������px�������������px�������������px�������������px�������������pxwwwwwwwwwwwwwxpx��������������pxDDDDDDDDD@    pxDDDDDDDDDH���pxDDDDDDDDDH���pxDDDDDDDDDDDDDDpx��������������pwwwwwwwwwwwwwwwp��������������������������������                                                                                                                                (      �� ��
     	        (                                          �  �   �� �   � � ��  ��� ���   �  �   �� �   � � ��  ��� ��������        wwwwwwwpx������px������px������px������px������px������px������pxwwwwwwpxDDD���pxDDDDDDpx������pwwwwwwww��������                                                                �      �� ��     	        (   0   `                             qj� {r�     �R' �Q' �P' �H# �S$ �S% �R& �S& �R& �R' �hC �W! �V" �V" �U# �U$ �iP �Z �Z �Y �X  �X  �^ �] �] �[ �\ �a �` �` �_ �g �g �d �c �l
 �k �i �i �h �i �e) ʌP �b  �b �b �t �s �_ �[ �[ �c �r �v �p �b �q �o �p �x
 �n	 �h	 �w �o �t �y" �}' ߋ, Ȃ3 �E ֎@ ��U ��| ��� �s  �q  �f  �c  �b  �c  �t �u �t �r �j �e �c �c �] �[ �\ �u �v �t �u �t �e �] �\ �v �u �v �u �q �n �o �\ �v �w �u �v �u �w �v �w �w �v �w �x	 �x
 �y �z �z �z �{ �y �w ݂ �t �t �' �( �, �, �- �- �. �0 �0 �0 �0 �1 �3 ی1 �6 �7 �8 �8 �8 �: �= �> �= �@ �? �B �D �E �I �I �I �S �^ ��� ��� ��� ��� ��� ��� ��� ��� ��� ��� ��� ��� Fp� cq� ��� sss ppp iii aaa ``` ___ ]]] [[[ YYY XXX                                                                                                                                                                                                                                                                     ����������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������	��������������������������������������������
������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������!�� ��������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������%��������������������������������������������%��$��������������������������������������������$��"��������������������������������������������#��"��������������������������������������������#��"��������������������������������������������#��*��������������������������������������������+��(��������������������������������������������)��'��������������������������������������������'��&��������������������������������������������&��?��������������������������������������������?��<��������������������������������������������=��9��������������������������������������������;��7��������������������������������������������A��63[4]5mm]5\]m]mm5\mm5555555\\\5\\\5m\55\\5ed:���cOXY/P.Z0.0.QR00/ZPP0000000/0PPZR.BI@/DE0, �C��WkV21TSav^8{|}>qooggggggg1`_fhsnHK�{JLp��G���l�����������������������������������������-F�j���Nw~ytMMMMMMUbbrrrrrxxxxxxxxrriUMMMMMMMMMUuzt���������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������  ������  ������  ������  �                                                                                                                                                                                                                                                                         �      ������  ������  ������  ������  ������  �      �� ��     	        (       @                             ~r�     YRO �M" �M" �M" �O$ �S( �S) xH0 ~L3 wG0 wH0 rE. xI1 �YB \TP XRO �K �N! �O" �N" �N" �O$ xI0 pE. ZSO �h: �lA �j@ Ȕs Ǘz �B  �@  �i7 ̖q ʕr YSO b_] �F  �E  �C  �D  �E  �C  �n5 �l6 �f> Ηn ɗs [TO �L  �I  �J  �I  �s- �r. �p0 �o1 לj ��_ ՛k Қl Йm ZTO �Y  �K  �I �w* �v, ۞h ٝi �i  �Y  �S  �{$ �z& �x' ߢe ݡf �m  �k  �l  �m  �n  �o  �n  �j  �m  �k  �q �} �$ ކ* ݉* �7 �? ��D Ջ; �@ �Q �b �c �b �b �o  �f  �q �r �x � � � �{ �z �{ �z �u ۀ ܀ ܀ ܁ ܁ ܂ ܃ ܂ ݃ ݄ ܄ ݄ ݅ �! ݆ �$ ݆! �& �' �* �+ �- ۉ* �/ �/ �3 �3 ��5 �6 �5 �7 �7 �8 �; �= �? ԍ7 ��V �p ��� ^][ �Ҫ �Ѵ �϶ �ϴ �ϵ �ͳ �ѷ �ҹ �ӹ �ҹ �Ӹ �ӹ �ս ��� ��� ��� ��� ��� ��� ��� ��� ��� .j� ��� ��� ttt ```                                                                                                                                                                                                                                                                                         ����������������������������������������������������������������������������������������������������������������������������������		
&�������������������������������1������������������������������������������������������������"���������������������������$��.���������������������������#%��-���������������������������0%��:���������������������������?%��9���������������������������>%��8���������������������������=%��7���������������������������;��E���������������������������G@��D���������������������������F@��M���������������������������O@��L���������������������������N2��K���������������������������h2��\���������������������������g2��]���������������������������f2��[�������������������������������I3')+*+)))*))()*+++,6J!54 CBA���jYPQTVTSkllZTTXRTUiHceWda/� i���u����`�������������������_<bm����t^��}zy|yx~���{|yvrrwsqpon������������������������������������������������������������������������������������������������������������������������������������������������   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �  �  ����������������h      �� ��     	        (                                        |WR ��� �Q3 �O1 ��b sP? �Q2 �Q2 �Y9 �^G ײ� �`E ۹� �cE �bE ݹ� ��� �o7 �f@ �gD �eD 㼜 ໝ �Ü 徚 �b �c �c �d �c �d �d �s  �x( ·> �zZ 翘 ��� �g ഄ ��x �$ �& �* �+ �+ �, �- �- �/ �0 �4 �6 ��I ��� ��� ��� ��� �ڽ ��� ��� ��� ��� ��� ��� ��� ��� ��� ��� ��� ��� ��� ��� ��� ��� ���  ~~~ }}}                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 PPPPPPPPPPPPPPPPPKMNNNNNNNNNNOLO	O&:
OJHHGGGGGGGGHI
OJEEEEEEEEEEFCOJEEEEEEEEEEFCOJEEEEEEEEEEFDOJEFEEEEEEEEEBO%JEEEEEEEEEFFBOJJIIIIJIIIIJJO(@>=77A779?<8;$O' "!)O6530./21+*-,4#4PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP����� ��  ��  ��  ��  ��  ��  �  ��  ��  ��  ��  �� ����������%      �� ��     	        (   0   `                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��H#��P'��Q'��Q'��Q'��Q'�   �   �Q&ݤR&��R&��R'��R&��R&��R&��R&��R&��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��R'�   �   �R&����������������������������������������������������������������������������������������������������������������������������������������������������������������������������������S&�   �   �S%����������������������������������������������������������������������������������������������������������������������������������������������������������������������������������S$�   �   �U$����������������������������������������������������������������������������������������������������������������������������������������������������������������������������������U#�   �   �V"����������������������������������������������������������������������������������������������������������������������������������������������������������������������������������V"�   �   �W!����������������������������������������������������������������������������������������������������������������������������������������������������������������������������������X �   �   �Y����������������������������������������������������������������������������������������������������������������������������������������������������������������������������������X �   �   �Z����������������������������������������������������������������������������������������������������������������������������������������������������������������������������������Z�   �   �\����������������������������������������������������������������������������������������������������������������������������������������������������������������������������������[�   �   �]����������������������������������������������������������������������������������������������������������������������������������������������������������������������������������]�   �   �^����������������������������������������������������������������������������������������������������������������������������������������������������������������������������������_�   �   �`����������������������������������������������������������������������������������������������������������������������������������������������������������������������������������`�   �   �a����������������������������������������������������������������������������������������������������������������������������������������������������������������������������������a�   �   �a����������������������������������������������������������������������������������������������������������������������������������������������������������������������������������a�   �   �a����������������������������������������������������������������������������������������������������������������������������������������������������������������������������������a�   �   �a����������������������������������������������������������������������������������������������������������������������������������������������������������������������������������a�   �   �a����������������������������������������������������������������������������������������������������������������������������������������������������������������������������������a�   �   �a����������������������������������������������������������������������������������������������������������������������������������������������������������������������������������a�   �   �a����������������������������������������������������������������������������������������������������������������������������������������������������������������������������������a�   �   �c����������������������������������������������������������������������������������������������������������������������������������������������������������������������������������c�   �   �d����������������������������������������������������������������������������������������������������������������������������������������������������������������������������������d�   �   �g����������������������������������������������������������������������������������������������������������������������������������������������������������������������������������g�   �   �g����������������������������������������������������������������������������������������������������������������������������������������������������������������������������������g�   �   �g����������������������������������������������������������������������������������������������������������������������������������������������������������������������������������g�   �   �h����������������������������������������������������������������������������������������������������������������������������������������������������������������������������������i��   �i����������������������������������������������������������������������������������������������������������������������������������������������������������������������������������i��   !�k����������������������������������������������������������������������������������������������������������������������������������������������������������������������������������k��   "�l
����������������������������������������������������������������������������������������������������������������������������������������������������������������������������������l
��   "�n	����������������������������������������������������������������������������������������������������������������������������������������������������������������������������������n	��   "�o����������������������������������������������������������������������������������������������������������������������������������������������������������������������������������p��   "�p����������������������������������������������������������������������������������������������������������������������������������������������������������������������������������q��   !�r����������������������������������������������������������������������������������������������������������������������������������������������������������������������������������w��   �c��_��]��[��\��[��\��\��\��[��[��\��\��\��\��\��[��[��\��\��[��[��[��[��[��[��[��[��[��[��[��[��[��[��[��\��[��[��[��[��[��[��\��]��b��t��   �e��f ��e��c��b��c ��b ��c��b��b ��b��b ��b ��c ��b��b��b��c��c ��c ��b��b��b��b��b��b��b��b��b��c ��c ��c��c ��b ��o�֎@��h	��b��y"��}'��b��e)�qj���iP��t��t��   �j��n��r��s��t��u��t��u��w��u��v��y��{��z��{��z��x
��v��w��w��u��u��u��u��u��u��u��t��t��v��v��v��w��v��E���|�݂��y���U������u�{r��Fp��cq��Ȃ3��w�   �   �o��y��S��^��E��D��I��I��D��:��B��I��6��3��8��?��@��=��>��>��=��=��=��=��=��=��=��8��,��0��0��-��.��(��'��,��0��-��0��1��7��8�ʌP�ߋ,�ی1��q�   J   �w 1�q ��v��z��x	��v��s ��s ��s ��s ��s ��s ��t��t��t��u��u��u��u��u��w��w��w��w��w��w��w��w��u��u��u��t��s ��s ��s ��s ��s ��s ��s ��s ��s ��t��w��x
��v��` W                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ������  ������  ������  �                                                                                                                                                                                                                                                                                                                             ������  ������  ������  ������  ������  �      �� ��     	        (       @                                                                                                                                                                                                                                                                                                                                                                                                     ^   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   i   �G ��>�:��9��8��8��8��9��:��:��:��:��:��:��:��:��:�:�:�:�:�:�:�:�:�:�:�:�:�i2�	�   ,�K��S(��O$��N!��N!��N!��N!��N"��M"��M"��M"��M"��M"��M"��M"��M"��M"��M"��M"��M"��M"��M"��M"��M"��N"��M"��M"��O$��S)��O"��   1�lA�����������������������������������������������������������������������������������������������������������������ɗs�#�   -�j@�����������������������������������������������������������������������������������������������������������������Ǘz�
�   +�h:�����������������������������������������������������������������������������������������������������������������Ȕs�	 �   +�i7�����������������������������������������������������������������������������������������������������������������ʕr�
 �   +�l6�����������������������������������������������������������������������������������������������������������������̖q�
 �   +�n5�����������������������������������������������������������������������������������������������������������������Ηn�
 �   +�o1�����������������������������������������������������������������������������������������������������������������Йm� �   +�p0�����������������������������������������������������������������������������������������������������������������Қl� �   *�r.�����������������������������������������������������������������������������������������������������������������՛k� �   #�r.�����������������������������������������������������������������������������������������������������������������՛k� �   "�s-�����������������������������������������������������������������������������������������������������������������לj� �   "�v,�����������������������������������������������������������������������������������������������������������������ٝi� �   "�w*�����������������������������������������������������������������������������������������������������������������۞h� �   "�x'�����������������������������������������������������������������������������������������������������������������ݡf� �   "�z&�����������������������������������������������������������������������������������������������������������������ߢe� �   "�{$������������������������������������������������������������������������������������������������������������������b� �   "�$������������������������������������������������������������������������������������������������������������������b� �   "ކ*������������������������������������������������������������������������������������������������������������������c� �   "�}������ս��ҹ��ҹ��ӹ��ӹ��ҹ��ӹ��ӹ��ӹ��ӹ��ҹ��ӹ��ҹ��ҹ��ҹ��ҹ��ҹ��ҹ��Ӹ��϶��ͳ��ѷ��ϵ��ϴ��Ѵ��Ҫ�����ԍ7��   "�Y ��L ��F ��C ��E ��D ��E ��C ��C ��C ��D ��C ��C ��E ��C ��C ��D ��E ��E ��E ��C ��I ��S ��@ ��J ��I ��B ��I��K ��Y ��   $�f ��k ��m ��k ��n ��n ��n ��m ��q��r��r��q��n ��n ��m ��m ��l ��n ��o ��o ��i ��@��b��j ��Q���D��f>�.j��~r���o ��   �n �ۉ*���V��=��;��?��7��3��?��/��/��8��7��5��6��6��-��&��*��'��!��+��3��$��3���5��7���_�Ջ;��x�h   �t b�x�܄�܀��}��{��z��z
��|��z	��y
��|��}��}������~��{��|��z	��y��s ��s ��y��t ��t ��{ ��} ��|��m �                                                                                                                                                                                                                                                                                                                                                                                                       ���������                                                                                                          ������������h      �� ��     	        (                                                                                      
      k   �   �   �   �   �   �   �   �   �   �   �   �   {   O�O&��F#�C!�C!�C!�C!�C!�C!�C!�C!�C!�C!�A �E$�R(�   pְ������������������������������������������������������rE+�   pٵ������������������������������������������������������qD)�   p۵������������������������������������������������������tF'�   p޷������������������������������������������������������wH'�   pḖ�����������������������������������������������������zI&�   p五�����������������������������������������������������}L%�   p滒������������������������������������������������������N%�   p���������������������������������������������������������M!�   pް}��������������������������������������������������ڽ��c>�   p�c��d��c��d��d��d��c��b��c��c��x(��s ��o7�|WR��zW�   R�y��*����������������������$��1�mp   	                                                                                                                                � :�  ��  ��  ��  ��  ��  ��  ��  ��  ��  ��  ��  ��  ����������v       �� ��y     0	                 �  	    (  
 00    �         �       h   00     �%          �        h           �� ��     0 	        4   V S _ V E R S I O N _ I N F O     ���    �     �                             b   S t r i n g F i l e I n f o   >   0 4 0 9 0 4 b 0   � 8  F i l e D e s c r i p t i o n     C h r o m i u m   E m b e d d e d   F r a m e w o r k   ( C E F )   U n i t   T e s t   A p p l i c a t i o n   r )  F i l e V e r s i o n     1 3 4 . 3 . 8 + g f e 6 6 d 8 0 + c h r o m i u m - 1 3 4 . 0 . 6 9 9 8 . 1 6 6     2 	  I n t e r n a l N a m e   c e f t e s t s     � ;  L e g a l C o p y r i g h t   C o p y r i g h t   ( C )   2 0 2 5   T h e   C h r o m i u m   E m b e d d e d   F r a m e w o r k   A u t h o r s     B   O r i g i n a l F i l e n a m e   c e f t e s t s . e x e     � 8  P r o d u c t N a m e     C h r o m i u m   E m b e d d e d   F r a m e w o r k   ( C E F )   U n i t   T e s t   A p p l i c a t i o n   v )  P r o d u c t V e r s i o n   1 3 4 . 3 . 8 + g f e 6 6 d 8 0 + c h r o m i u m - 1 3 4 . 0 . 6 9 9 8 . 1 6 6     D    V a r F i l e I n f o     $    T r a n s l a t i o n     	�