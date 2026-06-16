const { RtcTokenBuilder, RtcRole } = require('agora-token');

function generateAgoraToken(channelName, uid, role = RtcRole.PUBLISHER, expireTime = 3600) {
  const currentTime = Math.floor(Date.now() / 1000);
  const privilegeExpireTime = currentTime + expireTime;
  return RtcTokenBuilder.buildTokenWithUid(
    process.env.AGORA_APP_ID,
    process.env.AGORA_APP_CERTIFICATE,
    channelName, uid, role, privilegeExpireTime
  );
}
module.exports = { generateAgoraToken };
