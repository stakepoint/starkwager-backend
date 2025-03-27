import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { SendgridService } from './sendgrid.service';

@Module({
  imports: [ConfigModule],
  providers: [SendgridService],
  exports: [SendgridService],
})
export class SendgridModule {}
